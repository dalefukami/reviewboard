require 'rubygems'
require 'typhoeus'
require 'json'

module ReviewBoard
  class ReviewBoard
    def initialize( user, pass, url )
      @user = user
      @pass = pass
      @base_url = url + "/api"
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

    def get_review_diffs(review_number)
      #XXX Used?
      review_path = "review-requests/#{review_number}/diffs/1/files"
      response = make_request "#{review_path}/"

      value = JSON.parse(response.body)
    end

    def get_review_diff_chunks(review_number, diff_id, file_diff_id)
      response = make_request "review-requests/#{review_number}/diffs/#{diff_id}/files/#{file_diff_id}/"

      value = JSON.parse(response.body)
    end

    def get_new_file_line_map(review_number)
      #XXX Not really reviewboards responsibility. Pull out to the review class and just call get_review_diff_chunks?
      review_path = "review-requests/#{review_number}/diffs/1/files/25083"
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

      line_maps = {'source' => source_line_map, 'new' => new_line_map}
      pp line_maps
    end

    def post_review_draft_comment(review_number, review_id, comment_info)
      review_path = "review-requests/#{review_number}/reviews/#{review_id}/diff-comments"
      response = post "#{review_path}/", comment_info

      JSON.parse(response.body)
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
end
