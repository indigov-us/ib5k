ENV['ENVIRONMENT'] = 'production'
require "#{File.expand_path(File.dirname(__FILE__))}/lib/config.rb"
CWC::User.all.each do |user|
  messages = user.messages.where(:created_at.gte => Date.today-1).to_a
  mail = Mail.deliver do
    from    'cwc_app@mail.house.gov'
    to      user.email
    subject 'CWC Test: Daily Report'
    body    "[#{messages.size}] messages received in the last 24h\n\n\n\n"+messages.map{|m| m.xml}.join("\n=================\n")
  end
end
