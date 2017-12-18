ENV['ENVIRONMENT'] = 'production'
require "#{File.expand_path(File.dirname(__FILE__))}/../lib/config.rb"

if ARGV[0] && ARGV[0].size > 2
  puts "THIS WILL DELETE ALL THE DATA AND EXPORT IT TO #{ARGV[0]} directory"
  puts "If you are sure please type 'yes, delete all' to continue"
  c = $stdin.gets.strip
  CWC.archive_and_remove_all_messages(ARGV[0],c)
  if c == 'yes, delete all'
    puts "Done"
  else
    puts "Aborted"
  end
else
  puts "Please supply the output directory as a first parameter"
  puts "\t for example "
  puts "cd /home/gyordano/production/cwc/utils && bundle exec database_export.rb /tmp/todays_export/"
end
