#!/usr/bin/env ruby

# Add the library from the source tree to the front of the load path.
# This allows ti to run without first installing a ticgit gem, which is
# important when testing multiple branches of development.
if File.exist? File.join(File.dirname(__FILE__), '..', 'lib', 'cli', 'cli.rb')
  $LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
end

require 'cli/cli'

cli = ReviewBoard::Cli::CommandLineInterface.new ARGV
cli.execute!
