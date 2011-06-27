require 'optparse'
require 'pp'

module ReviewBoard
  module Cli
    module Command
      class Request
        attr_accessor :user_name

        def initialize rb
          @rb = rb
        end

        def parse_arguments args
          command = self
          parser = OptionParser.new do |opt|
            opt.banner = "Usage: reviewboard request [options]"
            opt.on( '-u', '--user_name USER_NAME', String, "User name" ) do |val|
                command.user_name = val
            end
          end
          parser.parse(args)

          if !@user_name 
            puts parser
            return false
          end
          return true
        end

        def execute
          reviews = @rb.get_reviews(@user_name)
          details = reviews.map { |review|
            {
              'id' => review['id'],
              'summary' => review['summary'],
            }
          }
          puts details.to_json
        end
      end
    end
  end
end
