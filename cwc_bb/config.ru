require "#{::File.expand_path(::File.dirname(__FILE__))}/cwc_api"

routes = {'/' => CWC::Api}

run Rack::URLMap.new routes
