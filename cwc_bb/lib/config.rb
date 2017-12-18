require 'rubygems'
require "bundler/setup"
require 'mongo'
require 'mongoid'
require 'yajl'
require 'pp'
require 'set'
require 'mail'
require 'digest/sha2'
require 'digest/md5'
require 'nokogiri'
require 'qu-mongo'

require "#{::File.expand_path(::File.dirname(__FILE__))}/xml_validator_v2"
require "#{::File.expand_path(::File.dirname(__FILE__))}/xml_generator_v2"
require "#{::File.expand_path(::File.dirname(__FILE__))}/exporter"

tmp_environment = :development
ENV['ENVIRONMENT'] = ENV['ENVIRONMENT'] || ENV['RACK_ENV']
if ENV['ENVIRONMENT']
  tmp_environment = ENV['ENVIRONMENT'].to_sym
end

# just in case - none is the simplest rack env - translate to production
if tmp_environment == :none
  tmp_environment = :production
end

if tmp_environment == :production
  mongoid_conn = Mongo::Connection.new 'cwc_data', 27017, :pool_size => 10
else
  mongoid_conn = Mongo::Connection.new 'localhost', 27017, :pool_size => 10
end

Qu.backend.max_retries = 0
Qu.configure do |c|
  c.connection = mongoid_conn.db("cwc_qu")
  c.logger = Logger.new(STDOUT)
  # c.logger.level = Logger::DEBUG  # in case we need to see what is going on there
  c.logger.level = Logger::INFO
end

Mongoid.configure do |c|
  c.max_retries_on_connection_failure = 5
  # c.skip_version_check = true
  c.identity_map_enabled = false

  begin
    db_name = 'cwc'

    if ENV['RACK_ENV']  && ENV['RACK_ENV'] == 'test'
      db_name = 'cwc_test'
    end
    c.master = mongoid_conn.db(db_name)

  rescue Exception=>err
    abort "An error occurred while creating the mongoid connection pool: #{err}"
  end
end

module CWC
  OFFICE_TO_EMAIL = JSON.parse(File.read("#{File.expand_path(File.dirname(__FILE__))}/data/office_to_email.json"))
end

# load all models
Dir.glob(File.expand_path(File.dirname(__FILE__)) + '/models/*.rb') {|file| require file}
