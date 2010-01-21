require File.dirname(__FILE__) + "/test_helper"

class DifferantTest < Test::Unit::TestCase
  
  def app
    GithubDifferant::App
  end
  
  def test_it_responds_to_request
    get "/"
    assert last_response.ok?
  end
  
  def test_it_returns_500_when_payload_is_missing
    post "/"
    assert_equal 500, last_response.status
  end
  
  # def test_it_returns_events_html
  #   get "/#{org_id}"
  #   assert last_response.body.include?("tag:eventbrite.com:event-483716810")
  # end
  # 
  # def test_it_returns_events_ical
  #   get "/#{org_id}.ical"
  #   assert  last_response.ok?
  #   assert_equal "text/calendar", last_response["Content-Type"]
  #   assert last_response.body.include?("UID:tag:eventbrite.com:event-483716810")
  #   assert last_response.body =~ /VCALENDAR/
  # end

end
