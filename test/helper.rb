require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'mocha'
require 'vcr'
require 'shoulda'

VCR.config do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.stub_with :typhoeus
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'reviewboard'

class Test::Unit::TestCase
end
