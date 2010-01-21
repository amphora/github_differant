require File.dirname(__FILE__) + "/../lib/github_differant"
require File.dirname(__FILE__) + "/../lib/github"

require "test/unit"
require "rack/test"

require 'fakeweb'
FakeWeb.allow_net_connect = false

module TestHelper
  def payload
    File.read(File.dirname(__FILE__) + "/fixtures/payload.json")
  end
end

class Test::Unit::TestCase
  include TestHelper
  include Rack::Test::Methods
end

class GithubDifferant::App
  include TestHelper
end
