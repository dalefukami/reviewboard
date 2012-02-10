require 'optparse'
require 'pp'

module ReviewBoard
  module Cli
    module Command
      class Comment
        attr_accessor :request_id, :review_id, :line, :comment, :number_of_lines, :file_diff_id, :diff_id, :file_version

        def initialize rb
          @rb = rb
        end

        def parse_arguments args
          @file_version = nil;

          command = self
          parser = OptionParser.new do |opt|
            opt.banner = "Usage: reviewboard comment [options]"
            opt.on( '-q', '--request REQUEST_ID', Integer, "Request Id" ) do |q|
                command.request_id = q
            end
            opt.on( '-r', '--review REVIEW_ID', Integer, "Review Id" ) do |r|
                command.review_id = r
            end
            opt.on( '-l', '--line LINE_NUMBER', Integer, "Line number" ) do |val|
                command.line = val
            end
            opt.on( '-c', '--comment COMMENT', String, "Comment" ) do |val|
                command.comment = val
            end
            opt.on( '-n', '--number_of_lines NUMBER', Integer, "Number of lines" ) do |val|
                command.number_of_lines = val
            end
            opt.on( '-d', '--diff_id DIFF_ID', Integer, "Diff id" ) do |val| #XXX  why did I need this?
                command.diff_id = val
            end
            opt.on( '-f', '--filediff_id FILEDIFF_ID', Integer, "File diff id" ) do |val|
                command.file_diff_id = val
            end
            opt.on( nil, '--dest', "Line number references dest_file" ) do
                command.file_version = 'dest'
            end
            opt.on( nil, '--source', "Line number references source_file" ) do
                command.file_version = 'source'
            end
          end

          parser.parse(args)

          if !@request_id || !@review_id || !@line || !@comment || !@number_of_lines || !@file_diff_id
            puts parser
            return false
          end
          return true
        end

        def execute
          diff_line = @line
          if @file_version
            #XXX Bad assumption, of course.
            latest_diff_id = @rb.get_latest_diff_id @request_id
            line_map = @rb.get_file_line_map @request_id, latest_diff_id, @file_diff_id

            diff_line = line_map[@file_version][@line]
          end

          #XXX Error handling
          result = @rb.post_review_draft_comment( @request_id, @review_id, {:first_line => diff_line, :text => @comment, :num_lines => @number_of_lines, :filediff_id => @file_diff_id} )

          comment = result['diff_comment']
          details = {
            'id' => comment['id'],
            'first_line' => comment['first_line'],
            'text' => comment['text'],
            'num_lines' => comment['num_lines'],
            'public' => comment['public'].to_s,
            'author' => comment['links']['user']['title']
          }

          puts details.to_json
        end
      end
    end
  end
end
