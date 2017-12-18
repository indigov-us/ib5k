
ENV['RACK_ENV'] = 'test'

require "#{File.expand_path(File.dirname(__FILE__))}/../cwc_api"
require 'factory_girl'
require 'qu-immediate'

Mongoid.logger = Logger.new($stdout)

# Dir["#{File.expand_path(File.dirname(__FILE__))}/helpers/*_helper.rb"].each { |h| require h }

require "#{File.expand_path(File.dirname(__FILE__))}/factories"

require 'minitest/autorun'
require 'rack/test'

Mail.defaults do
  delivery_method :test
end


def app
  CWC::Api
end

include Rack::Test::Methods

MiniTest::Spec.before do

  CWC.send(:remove_const, :OFFICE_TO_EMAIL)
  CWC.const_set(:OFFICE_TO_EMAIL, {})

  Mail::TestMailer.deliveries.clear

  Mongoid.master.collections.select do |collection|
    collection.name !~ /system/
  end.each(&:drop)
end
