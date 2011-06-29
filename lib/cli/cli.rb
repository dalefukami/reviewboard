require 'reviewboard'
require 'highline/import'

module ReviewBoard
  module Cli
    class CommandLineInterface
      def initialize(args)
        @args = args.dup

        initialize_credentials

        @rb = ReviewBoard.new @user, @pass, @url, @cookie
      end

      def execute!
        parse_options!

        if command = get_command(@action)
          command.execute unless !command.parse_arguments @args
        end
      end

      def parse_options!
        if @args.empty?
          exit_with_usage "Please specify at least one action to execute."
        end

        @action = @args.shift

        if !command_exists @action
          exit_with_usage "Invalid action [#{@action}] specified."
        end
      end

      def exit_with_usage msg
        puts msg
        puts
        puts usage
        exit 1
      end

      def usage(args = nil)
        old_args = args || [@action, *self.args].compact
        #XXX Add a usage message based on command list
      end

      def get_command(action)
        if !command_exists action
          return nil
        end

        require File.join(File.dirname(__FILE__), 'commands', action)
        class_name = camelize(action)
        return to_class("ReviewBoard::Cli::Command::#{class_name}").new @rb
      end

      def command_exists action
        Dir[File.dirname(__FILE__) + '/commands/*.rb'].each do |file|
          if action == File.basename(file, File.extname(file))
            return true
          end
        end

        return false
      end



      private

      def camelize(str)
        str.split('_').map {|w| w.capitalize}.join
      end

      def to_class str
        chain = str.split "::"
        klass = Kernel
        chain.each do |klass_string|
          klass = klass.const_get klass_string
        end
        klass.is_a?(Class) ? klass : nil
      rescue NameError
        nil
      end

      def initialize_credentials
        if File.exists?('/home/dale/.rb_cookie')
          @cookie = File.open('/home/dale/.rb_cookie', 'r').read
        else
          @user = ask("Reviewboard username: ") {|q| q.echo = true}
          @pass = ask("Reviewboard password: ") {|q| q.echo = false}
        end

        if File.exists?('/home/dale/.reviewboardrc')
          @rb_config = File.open('/home/dale/.reviewboardrc', 'r').read
          matches = @rb_config.match("REVIEWBOARD_URL\s*=\s*\"http://\(.*\)\"$")
          @url = matches[1]
        else
          @url = ask("Reviewboard url: ") {|q| q.echo = true}
        end
      end

    end
  end
end
