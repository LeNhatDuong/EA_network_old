# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

#whenever --update-crontab --set environment=development
require File.expand_path(File.dirname(__FILE__) + "/environment")

CONFIGS = YAML.load(File.read("#{Rails.root}/config/config.yml"))[@environment]

set :output, File.join(Rails.root, "log", "crontab.log")

every :hour do # Many shortcuts available: :hour, :day, :month, :year, :reboot
  command "#{File.join(Rails.root, 'script', 'speed_test_client')} #{CONFIGS['host']}"
end

every :reboot do
  command "sudo nginx"
  command "redis-server --port 6379 --daemonize yes --pidfile #{Rails.root}/tmp/redis.pid --logfile #{Rails.root}/log/redis.log"
  command "cd #{Rails.root} && bundle exec sidekiq --index 0 --pidfile #{Rails.root}/tmp/pids/sidekiq.pid --environment production --logfile #{Rails.root}/log/sidekiq.log --daemon"
end
