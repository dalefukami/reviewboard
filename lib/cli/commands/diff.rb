require 'optparse'
require 'pp'

module ReviewBoard
  module Cli
    module Command
      class Diff
        attr_accessor :request_id

        def initialize rb
          @rb = rb
        end

        def parse_arguments args
          command = self
          parser = OptionParser.new do |opt|
            opt.banner = "Usage: reviewboard comment [options]"
            opt.on( '-q', '--request REQUEST_ID', Integer, "Request Id" ) do |q|
                command.request_id = q
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
          comments = @rb.get_diff_file_comments( @request_id )
          comment_details = comments.map { |comment|
            {
              'id' => comment['id'],
              'first_line' => comment['first_line'],
              'text' => comment['text'],
              'num_lines' => comment['num_lines']
            }
          }
          pp comment_details
          #XXX Clean output
          #XXX Error handling
        end
      end
    end
  end
end
