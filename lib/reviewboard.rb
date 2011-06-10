require 'json'
require 'pp'

class ReviewBoard
  def initialize
    @user = "info"
    @pass = "*******"
    @base_url = "http://*******/api"
  end

  def draft(review_number)
    response = make_request "review-requests/#{review_number}/"
    value = JSON.parse(response.body)
    pp value
  end

  private

  def make_request(resource)
    Typhoeus::Request.get(
      "#{@base_url}/#{resource}",
      :username => @user,
      :password => @pass
    )
  end
end
