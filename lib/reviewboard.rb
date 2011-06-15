require 'typhoeus'
require 'json'
require 'pp'

class ReviewBoard
  def initialize
    @user = "info"
    @pass = "*******"
    @base_url = "http://*******/api"
  end

  def get_review_draft_id(review_number)
    review_path = "review-requests/#{review_number}/reviews"
    response = make_request "#{review_path}/draft/"
    if response.code === 404
      return nil
    elsif response.code != 301
      return nil
    end

    matches = response.headers_hash[:Location].match(".*#{review_path}/(\\d+)")
    draft_id = matches[1]
  end

  def get_review_draft(review_number, review_id)
    review_path = "review-requests/#{review_number}/reviews/#{review_id}"
    response = make_request "#{review_path}/"

    value = JSON.parse(response.body)
    pp value
  end

  def get_review_draft_comments(review_number, review_id)
    review_path = "review-requests/#{review_number}/reviews/#{review_id}/diff-comments"
    response = make_request "#{review_path}/"

    value = JSON.parse(response.body)
    pp value
  end

  def get_review_draft_comment(review_number, review_id, comment_id)
    review_path = "review-requests/#{review_number}/reviews/#{review_id}/diff-comments/#{comment_id}"
    response = make_request "#{review_path}/"

    value = JSON.parse(response.body)
    pp value
  end

  def get_review_diffs(review_number)
    review_path = "review-requests/#{review_number}/diffs/1/files"
    response = make_request "#{review_path}/"

    value = JSON.parse(response.body)
    pp value
  end

  def post_review_draft_comment(review_number, review_id)
    review_path = "review-requests/#{review_number}/reviews/#{review_id}/diff-comments"
    response = post "#{review_path}/", {:first_line => 460, :text => 'my first comment', :num_lines => 3, :filediff_id => 25083}

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

  def post(resource, params)
    Typhoeus::Request.post(
      "#{@base_url}/#{resource}",
      :username => @user,
      :password => @pass,
      :params => params
    )
  end
end
