require "#{File.expand_path(File.dirname(__FILE__))}/lib/config.rb"
require 'sinatra/base'
require 'sinatra/reloader'
require "sinatra/json"

module CWC
  class Api < Sinatra::Base
    register Sinatra::Reloader

    set :app_file,       __FILE__
    set :logging,        false
    set :root,           ::File.join(::File.expand_path(::File.dirname(__FILE__)), '/')
    set :views,          ::File.join(::File.expand_path(::File.dirname(__FILE__)), '/views')
    set :public_folder,  ::File.join(::File.expand_path(::File.dirname(__FILE__)), '/public')
    set :run,            false
    set :static,         true
    set :methodoverride, true

    configure do
      Dir["#{::File.expand_path(::File.dirname(__FILE__))}/lib/rest/*.rb"].each{|r| require r}
      also_reload "#{::File.expand_path(::File.dirname(__FILE__))}/lib/**/*.rb"
      Thread.new{
        Qu::Worker.new('default').start
      }
    end

    helpers Sinatra::JSON

    helpers do
      def require_apikey
        key = params['apikey'] || request.env['X-APIKEY'] || request.env['HTTP_X-APIKEY'] || request.env['HTTP_X_APIKEY']
        if !key
          halt 401, 'Api Key required !'
        end

        u = User.where(activated:true,apikey:key).first
        if !u
          halt 401, 'Api Key required !'
        end
        u
      end
    end

    get '/' do
        send_file File.join(settings.public_folder, 'index.html')
    end

    get '/confirm/:id/:key' do |id,key|
      user = User.where({_id:id,apikey:key,activated:false}).first
      if user
        user.activated = true
        user.save
        redirect to('/registration_activated.html')
      end
      redirect to('/registration_cannot_activate.html')
    end

    post '/register' do
      required = %w{first_name last_name email phone organization}

      required.each do |required_param|
        if !params[required_param] || params[required_param].size < 3
          redirect to('/registration.html')
        end
      end

      if !params['tos']
        redirect to('/registration.html')
      end

      if User.where(email:params['email']).count > 0
        # user with this email already exists - go away
        redirect to('/registration.html')
      end

      user = User.create({
                           email:params['email'],
                           first_name:params['first_name'],
                           last_name:params['last_name'],
                           phone:params['phone'],
                           organization:params['organization']
                         })

      body = File.read("#{File.expand_path(File.dirname(__FILE__))}/public/registration_email_template.tpl")
      body = body.gsub('{email}', user.email)
      body = body.gsub('{apikey}', user.apikey)
      body = body.gsub('{url}', url("/confirm/#{user.id}/#{user.apikey}"))

      mail = Mail.deliver do
        from    'cwc_app@mail.house.gov'
        to      user.email
        subject 'CWC API Registration'
        body    body
      end

      redirect to('registration_success.html')
    end

  end
end
