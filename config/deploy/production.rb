# Common server-specific settings
set :primary_domain, '192.168.1.37'
set :primary_user,   'eastagile8'

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.
role :app, "#{fetch(:primary_user)}@#{fetch(:primary_domain)}"
role :web, "#{fetch(:primary_user)}@#{fetch(:primary_domain)}"
role :db,  "#{fetch(:primary_user)}@#{fetch(:primary_domain)}"

set :branch,    'master'
set :rails_env, 'production'
set :deploy_to, "/Users/#{fetch(:primary_user)}/code/production/EastAgile_networking"

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

server fetch(:primary_domain), user: fetch(:primary_user), roles: %w{web app}


# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
set :ssh_options, {
  keys: "server-ssh-key",
  forward_agent: true
}
#
# And/or per server (overrides global)
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
