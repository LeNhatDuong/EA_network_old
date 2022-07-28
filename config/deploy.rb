# config valid only for current version of Capistrano
lock '3.3.5'

set :application, 'EastAgile_networking'
set :repo_url, 'git@github.com:EastAgile/EastAgile_networking.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :rvm_ruby_version, 'ruby-2.1.5'

set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do
  desc 'Link configs for shared folder'
  task :symlink_config do
    on roles(:app) do
      execute "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
      execute "ln -nfs #{shared_path}/config/config.yml #{release_path}/config/config.yml"
      execute "ln -nfs #{shared_path}/config/secrets.yml #{release_path}/config/secrets.yml"
      execute "rm -rf  #{release_path}/{tmp,log}"
      execute "ln -sFf #{shared_path}/tmp #{release_path}/tmp"
      execute "ln -sFf #{shared_path}/log #{release_path}/log"
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      invoke 'redis:start'
      execute "#{release_path}/script/change_gateway"
    end
  end

  after :publishing, :restart
  after :updating, :symlink_config
end

namespace :redis do
  desc 'Start the Redis server'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute "redis-server --port 6379 --daemonize yes --pidfile #{shared_path}/tmp/pids/redis.pid --logfile #{shared_path}/log/redis.log"
    end
  end

  desc 'Stop the Redis server'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'echo "SHUTDOWN" | nc localhost 6379; true'
    end
  end
end

namespace :nginx do
  desc 'Start nginx'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      sudo 'nginx'
    end
  end

  desc 'Stop nginx'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      sudo 'nginx -s stop; true'
    end
  end
end

before :deploy, 'nginx:stop'
before :deploy, 'redis:stop'
after :deploy, 'nginx:start'
