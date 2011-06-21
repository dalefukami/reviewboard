require 'helper'

class ReviewBoardTest < Test::Unit::TestCase
  def setup
    @rb = ReviewBoard.new "info", "nopass", "http://*******"
  end

  def test_get_review_draft_id
    VCR.use_cassette("get_draft_id") do
      @draft_id = @rb.get_review_draft_id(494)
    end

    assert_equal 739, @draft_id
  end
end
