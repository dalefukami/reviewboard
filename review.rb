require 'rubygems'

require File.join( File.dirname(__FILE__), 'lib','reviewboard')

class Review
  def initialize
    @reviewboard = ReviewBoard.new
  end

  def draft review_request_id
    draft_id = @reviewboard.get_review_draft_id(review_request_id)
#XXX     @reviewboard.get_review_draft_comments(review_request_id, draft_id)
#XXX     @reviewboard.get_review_draft_comment(review_request_id, draft_id, 1992)
#XXX     @reviewboard.get_review_diffs(review_request_id)
    @reviewboard.post_review_draft_comment(review_request_id, draft_id)
  end
end

review = Review.new

review.draft(494)
