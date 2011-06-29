require 'rubygems'
require 'typhoeus'
require 'json'
require 'net/http'
require 'pp' #XXX temp

module ReviewBoard
  class ReviewBoard
    def initialize( user, pass, url, cookie )
      @user = user
      @pass = pass
      @cookie = cookie
      @http = Net::HTTP.new(url, 80)
    end

    def get_reviews(users)
      params = {
        'status' => 'pending',
        'to-users' => users,
        'max-results' => '5'
      }
      response = get "review-requests/", params
      value = JSON.parse(response)
      value['review_requests']
    end

    def get_review_draft_id(review_number)
      review_path = "review-requests/#{review_number}/reviews"
      response = get "#{review_path}/draft/"
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
      response = get "#{review_path}/"

      value = JSON.parse(response)
      pp value
    end

    def get_review_comments(review_number, review_id)
      #XXX Used?
      review_path = "review-requests/#{review_number}/reviews/#{review_id}/diff-comments"
      response = get "#{review_path}/"

      value = JSON.parse(response)
    end

    def get_review_comment(review_number, review_id, comment_id)
      #XXX Used?
      review_path = "review-requests/#{review_number}/reviews/#{review_id}/diff-comments/#{comment_id}"
      response = get "#{review_path}/"

      value = JSON.parse(response)
    end

    def get_request_diffs(request_id)
      response = get "review-requests/#{request_id}/diffs/"

      value = JSON.parse(response)
      value['diffs']
    end

    def get_latest_diff_id(request_id)
      diffs = get_request_diffs request_id
      max_diff = diffs.max {|a,b| a['revision'].to_i <=> b['revision'].to_i}
      max_diff['revision']
    end

    def get_latest_diff(request_id)
      latest_diff_id = get_latest_diff_id request_id
      response = get "review-requests/#{request_id}/diffs/#{latest_diff_id}/"
      value = JSON.parse(response)
    end

    def get_latest_diff_files(request_id)
      latest_diff_id = get_latest_diff_id request_id
      response = get "review-requests/#{request_id}/diffs/#{latest_diff_id}/files/"
      value = JSON.parse(response)
      value['files']
    end

    def get_diff_file_comments(request_id)
      latest_diff_id = get_latest_diff_id request_id
      files = get_latest_diff_files request_id

      filediff_id = files[0]['id']
      response = get "review-requests/#{request_id}/diffs/#{latest_diff_id}/files/#{filediff_id}/diff-comments/"
      value = JSON.parse(response)
      value['diff_comments']
    end

    def get_review_diff_chunks(request_id, diff_id, file_diff_id)
      response = get "review-requests/#{request_id}/diffs/#{diff_id}/files/#{file_diff_id}/"

      value = JSON.parse(response)
    end

    def get_file_line_map(request_id, diff_number, file_diff_id)
      review_path = "review-requests/#{request_id}/diffs/#{diff_number}/files/#{file_diff_id}"
      response = get "#{review_path}/"

      value = JSON.parse(response)

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

      JSON.parse(response)
    end

    private

    def get(resource, params={})
      make_request Net::HTTP::Get, resource, params
    end

    def post(resource, params)
      make_request Net::HTTP::Post, resource, params
    end

    def make_request http_method, resource, params
      resource = "/api/#{resource}"
      path = resource + build_params(params)

      if @cookie.nil?
        req = http_method.new(path)
        req.basic_auth @user, @pass
      else
        @headers = { 'Cookie' => @cookie }
        req = http_method.new(path, @headers)
      end

      resp, data = @http.request(req)

      #XXX Not sure how to get this cookie back to save it. This doesn't seem to be the right place
      if @cookie.nil?
        @cookie = resp.response['set-cookie']
        File.open('/home/dale/.rb_cookie', 'w') {|f| f.write(@cookie) }
      end

      data
    end

    def build_params params
      params_strings = []
      params.each do |param|
        params_strings.push("#{param[0]}=#{param[1]}")
      end
      '?'+params_strings.join('&')
    end
  end
end
