require 'rubygems'
require 'sinatra/base'
require 'haml'

# for config
require 'yaml'

# for github
require 'json'
require 'rest_client'
require 'hashie'

# for email
require 'pony'

module GithubDifferant
  
  class App < Sinatra::Base

    CONFIG = File.dirname(__FILE__) + '/config.yml'
    set :views, File.dirname(__FILE__) + '/templates'
    
    get '/' do
      'github differant here.'
    end

    post '/' do
      halt 500 unless params["payload"]
      handle_payload params["payload"]
    end

    
    private

    def handle_payload(payload={})
      config  = File.exists?(CONFIG) ? YAML.load_file(CONFIG) : {:mail => nil, :smtp => {}, :github => {}}
      mail    = {:to => nil, :from => 'github-differant-post-receive'}.merge!(config[:mail])
      gh      = Github.new(config[:github][:login], config[:github][:token], payload)
      
      gh.commits.each do |commit|
        subject = "[GitHub] [#{commit.repo_name}] [#{commit.revision}] #{commit.message}"
        
        Pony.mail :to           => mail[:to],
                  :from         => mail[:from],
                  :subject      => subject,
                  :body         => message_body_for(commit, subject),
                  :content_type => 'text/html',
                  :via          => :smtp,
                  :smtp         => config[:smtp]
      end
      
    end # handle_payload
    
    def message_body_for(commit, title=nil)
      @title  = title
      @commit = commit
      haml :commit
    end

  end

  class Github
    
    BASE_URL  = "https://github.com/api/v2/json/"
    
    attr_accessor :login, :token, :payload
    
    def initialize(login, token, payload)
      @login    = login
      @token    = token
      @payload  = Hashie::Mash.new( JSON.parse(payload) )
    end
    
    def repo
      payload.repository.name
    end
    
    def user
      payload.repository.owner.name
    end
    
    def commits
      # create the array of commits we actually *want*
      collection = []
      
      payload.commits.each_with_index do |c, i|
        commit = commit(c.id)
        # get file contents for added diffs
        commit.added.map!{ |file| diff_hash(c.id, file.filename) }
        # get the previous tree for the removed files
        previous = i == 0 ? payload.before : payload.commits[i-1].id
        # get file contents for deleted diffs 
        commit.removed.map!{ |file| diff_hash(previous, file.filename) }
        
        # now add some fields we want
        commit.revision = commit.id.to_s[0..5]
        commit.repo_name = "#{user}/#{repo}"
        commit.repo = repo
        commit.user = user
        
        collection << commit
      end
      
      collection # return the new collection
    end
    
    def commit(sha)
      # commits/show/:user_id/:repository/:sha
      cm = get :commits, :show, user, repo, sha
      cm.commit
    end
    
    def blob(tree, path)
      # blob/show/:user/:repo/:tree_sha/:path
      bl = get :blob, :show, user, repo, tree, path
      bl.blob
    end
    
    def raw(sha)
      # blob/show/:user/:repo/:sha
      get :blob, :show, user, repo, sha
    end
    
    private
    
    def get(*args)
      url = BASE_URL + args.join("/")
      puts url.inspect
      resp = RestClient.get  url, :login => login, :token => token
      Hashie::Mash.new( JSON.parse(resp) )
    end
    
    # get the data for the blog and store it under the diff key
    def diff_hash(sha, path)
      begin
        blob = blob(sha, path)
        { "filename" => path, "diff" => blob.data}
      rescue
        { "filename" => path}
      end
    end
  end
  
end

