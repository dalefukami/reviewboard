require 'optparse'

module ReviewBoard
  module Cli
    module Command
      class DraftId
        attr_accessor :request_id
        attr_accessor :create

        def initialize rb
          @rb = rb
          @create = false
        end

        def parse_arguments args
          command = self
          parser = OptionParser.new do |opt|
            opt.banner = "Usage: reviewboard draft_id [options]"
            opt.on( '-q', '--request REQUEST_ID', Integer, "Request ID" ) do |q|
                command.request_id = q
            end
            opt.on( '-c', '--create' ) do |c|
                command.create = true
            end
          end
          parser.parse(args)

          if !@request_id 
            puts parser
            return false
          end
          return true
        end

        def execute
          draft_id = @rb.get_review_draft_id(@request_id)
          if draft_id.nil? && @create
            draft_id = @rb.create_review_draft(@request_id)
          end
          puts "#{draft_id}"
        end
      end
    end
  end
end
