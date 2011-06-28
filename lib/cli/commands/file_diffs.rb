require 'optparse'
require 'pp'

module ReviewBoard
  module Cli
    module Command
      class FileDiffs
        attr_accessor :request_id

        def initialize rb
          @rb = rb
        end

        def parse_arguments args
          command = self
          #CLEANUP: DRY the usage and option creation?
          parser = OptionParser.new do |opt|
            opt.banner = "Usage: reviewboard filediffs [options]"
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
          filediffs = @rb.get_latest_diff_files( @request_id )
          details = filediffs.map { |diff|
            {
              'id' => diff['id'],
              'dest_file' => diff['dest_file'],
            }
          }
          puts details.to_json
          #XXX Clean output
          #XXX Error handling
        end
      end
    end
  end
end
