require 'rubygems'
require 'typhoeus'
require 'json'
require 'pp' #XXX temp

module ReviewBoard
  class ReviewBoard
    def initialize( user, pass, url )
      @user = user
      @pass = pass
      @base_url = url + "/api"
    end

    def get_reviews(users)
      params = {
        'status' => 'pending',
        'to-users' => users,
        'max-results' => '5'
      }
      response = make_request "review-requests/", params
      value = JSON.parse(response.body)
      value['review_requests']
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
      draft_id = matches[1].to_i
    end

    def get_review_draft(review_number, review_id)
      #XXX Do we really need the draft object or can we just do everything without "formally" getting it?
      review_path = "review-requests/#{review_number}/reviews/#{review_id}"
      response = make_request "#{review_path}/"

      value = JSON.parse(response.body)
      pp value
    end

    def get_review_comments(review_number, review_id)
      #XXX Used?
      review_path = "review-requests/#{review_number}/reviews/#{review_id}/diff-comments"
      response = make_request "#{review_path}/"

      value = JSON.parse(response.body)
    end

    def get_review_comment(review_number, review_id, comment_id)
      #XXX Used?
      review_path = "review-requests/#{review_number}/reviews/#{review_id}/diff-comments/#{comment_id}"
      response = make_request "#{review_path}/"

      value = JSON.parse(response.body)
    end

    def get_request_diffs(request_id)
      response = make_request "review-requests/#{request_id}/diffs/"

      value = JSON.parse(response.body)
      value['diffs']
    end

    def get_latest_diff_id(request_id)
      diffs = get_request_diffs request_id
      max_diff = diffs.max {|a,b| a['revision'].to_i <=> b['revision'].to_i}
      max_diff['revision']
    end

    def get_latest_diff(request_id)
      latest_diff_id = get_latest_diff_id request_id
      response = make_request "review-requests/#{request_id}/diffs/#{latest_diff_id}/"
      value = JSON.parse(response.body)
    end

    def get_latest_diff_files(request_id)
      latest_diff_id = get_latest_diff_id request_id
      response = make_request "review-requests/#{request_id}/diffs/#{latest_diff_id}/files/"
      value = JSON.parse(response.body)
      value['files']
    end

    def get_diff_file_comments(request_id)
      latest_diff_id = get_latest_diff_id request_id
      files = get_latest_diff_files request_id

      filediff_id = files[0]['id']
      response = make_request "review-requests/#{request_id}/diffs/#{latest_diff_id}/files/#{filediff_id}/diff-comments/"
      value = JSON.parse(response.body)
      value['diff_comments']
    end

    def get_review_diff_chunks(request_id, diff_id, file_diff_id)
      response = make_request "review-requests/#{request_id}/diffs/#{diff_id}/files/#{file_diff_id}/"

      value = JSON.parse(response.body)
    end

    def get_file_line_map(request_id, diff_number, file_diff_id)
      review_path = "review-requests/#{request_id}/diffs/#{diff_number}/files/#{file_diff_id}"
      response = make_request "#{review_path}/"

      value = JSON.parse(response.body)

      source_line_map = {}
      new_line_map = {}

      chunks = value['diff_data']['chunks']
      chunks.each do |chunk|
        chunk['lines'].each do |line|
          diff_line_number, source_line_number, source_text, source_replaced_indexes, new_line_number, new_text, new_replaced_indexes, is_whitespace_only = line
          source_line_map[source_line_number] = diff_line_number unless source_line_number == ''
          new_line_map[new_line_number] = diff_line_number unless new_line_number == ''
        end
      end

      line_maps = {'source' => source_line_map, 'dest' => new_line_map}
    end

    def post_review_draft_comment(review_number, review_id, comment_info)
      review_path = "review-requests/#{review_number}/reviews/#{review_id}/diff-comments"
      response = post "#{review_path}/", comment_info

      JSON.parse(response.body)
    end

    private

    def make_request(resource, params={})
      Typhoeus::Request.get(
        "#{@base_url}/#{resource}",
        :username => @user,
        :password => @pass,
        :params => params
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
end
