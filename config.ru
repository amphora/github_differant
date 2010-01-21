require 'github_differant'

use Rack::ShowExceptions

run GithubDifferant::App.new