require 'rubygems'
require 'typhoeus'

require File.join( File.dirname(__FILE__), 'lib','reviewboard')

class Review
  def initialize
    @reviewboard = ReviewBoard.new
  end

  def draft review_id
    @reviewboard.draft(review_id)
  end
end

review = Review.new

review.draft(494)
