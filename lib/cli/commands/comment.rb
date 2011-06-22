require 'optparse'
require 'pp'

module ReviewBoard
  module Cli
    module Command
      class Comment
        attr_accessor :request_id, :review_id, :line, :comment, :number_of_lines, :file_diff_id

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
            opt.on( '-d', '--diff_id DIFF_ID', Integer, "Diff id" ) do |val|
                command.diff_id = val
            end
            opt.on( '-f', '--filediff_id FILEDIFF_ID', Integer, "File diff id" ) do |val|
                command.file_diff_id = val
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
          pp @rb.post_review_draft_comment( @request_id, @review_id, {:first_line => @line, :text => @comment, :num_lines => @number_of_lines, :filediff_id => @file_diff_id} )
          puts "Comment added"
          #XXX Clean output
          #XXX Error handling
        end
      end
    end
  end
end
