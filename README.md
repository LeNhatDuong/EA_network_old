# East Agile Netwoking
This application provides a looking glass to the networking status and speed across different lease lines that are being used at East Agile. Currently there are 5 of them. Below is the list of ISPs and their corresponding gateways at of May 2015:

 - **FPT1:** 192.168.1.1
 - **VNPT1:** 192.168.1.2
 - **VIETTEL1:** 192.168.1.3
 - **VIETTEL2:** 192.168.1.4

If you wish to change this list, refer to [Gateway config](#gateway-config).

# A bit of Technical Details
The core functionality of the application is to measure network upload and download speed to a [speedtest.net](http://www.speedtest.net/) server. We choose a fixed server located in *San Francisco, CA* for this purpose since the area is where most of our network connections are directed to when we are working with clients. This server is the one with `id="603"` in *speedtest*'s [list of servers](http://www.speedtest.net/speedtest-servers.php). The actual work is carried on by the [speedtest cli](https://github.com/sivel/speedtest-cli) at `script/speedtest_cli.py`.

A client script (`script/speed_test_client`) switches between the gateways and calls the *speedtest cli* to collect upload/download speed and then sends it back to our host server. By default we run this client script right on our host server, but you can actually run it from any client — just make sure to specify the correct host to report the test result to.

The parameters for `speed_test_client` are:

```bash
$ script/speed_test_client <host server> ["manual"]
```

The `manual` parameter indicates whether the test is carried out manually or by a scheduler.

# Host Machine Setup
**Notice:** the application is meant to be hosted on **Mac OS X**, so is this deployment guide.

> If you want to host this on a Linux environment, you need to adjust the `networksetup` command in `script/spped_test_client` and `script/change_gateway` with a corresponding network manager. Also, swap `brew` for your package manager and `launchd` for your service manager.

## Prerequisite

Assuming that the static IP address of the host machine is `192.168.1.39` and you are logging into a user called `eastagile` that has `sudo` access. If you are using another IP address or username, please change it accordingly in the steps below.

Install the following packages if you haven't:

### Install `brew`

```bash
$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

$ brew update
```
### Install `rvm`

```bash
$ brew install gnupg gnupg2

$ gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

$ \curl -sSL https://get.rvm.io | bash -s stable
```

After `rvm` installed, re-login to your shell for `rvm` to take effect — or you can apply the new changes immediately with:

```bash
$ source ~/.bash_profile

$ which rvm
/Users/eastagile/.rvm/bin/rvm
```

### Create `rvm` gemset

Install `ruby 2.1.5` for our application:

```bash
$ rvm install ruby-2.1.5

$ rvm --default use ruby-2.1.5
Using /Users/eastagile/.rvm/gems/ruby-2.1.5
```

Create the gemset for our application:

```bash
$ rvm gemset create eastagile-networking

$ rvm --default use ruby-2.1.5@eastagile-networking
Using /Users/eastagile/.rvm/gems/ruby-2.1.5 with gemset eastagile-networking

$ rvm gemset list
gemsets for ruby-2.1.5 (found in /Users/eastagile/.rvm/gems/ruby-2.1.5)
   (default)
=> eastagile-networking
   global
```

## Set up `nginx`

We will use `nginx` with `passenger` mod for our application. Since `nginx` does not support runtime extensions, we will need to install `passenger` first and then (re)compile `nginx` with `passenger` mod.

### Remove old instance

First, ensure that no existing instance of nginx and passenger exists:

```bash
$ brew uninstall nginx passenger
```

You need to do this manually if you have installed `nginx` and `passenger` using other methods, for example:

```bash
$ gem uninstall passenger
```

### Install `passenger`

Install `passenger` with:

```bash
$ brew install passenger

$ which passenger
/usr/local/bin/passenger
```

### Install `nginx` with `passenger`

Choose either method below.

**Notice:** if you got an error when testing your [`nginx` config](#test-nginx-config), uninstall `nginx` and and use *Method 2*.

#### Method 1

Using `brew`:

```bash
$ brew install nginx --with-passenger
```

#### Method 2

We will manually compile `nginx` with `passenger`. Make sure that we're using the correct `ruby` interpreter:

```bash
$ passenger-config --ruby-command
passenger-config was invoked through the following Ruby interpreter:
  Command: /Users/eastagile/.rvm/gems/ruby-2.1.5/wrappers/ruby
```

Now let `passenger` compile `nginx` for us:
```bash
$ passenger-install-nginx-module
```

> Input sequence when asked:
>
>  - Enter
>  - Enter
>  - 1
>  - `/usr/local/opt/nginx`

Link `nginx` binary to one of our `$PATH`s:

```bash
$ ln -s ../opt/nginx/sbin/nginx /usr/local/bin/nginx
```

### Configure `nginx`

#### Get the `passenger` settings

Notice the output of these commands:
```bash
$ passenger-config --root
/usr/local/Cellar/passenger/4.0.58/libexec/lib/phusion_passenger/locations.ini

$ passenger-config --ruby-command
...
  To use in Nginx : passenger_ruby /Users/eastagile/.rvm/gems/ruby-2.1.5@eastagile-networking/wrappers/ruby
...
```

#### Create `nginx` config

**Notice:** The `nginx` config file is located at `/usr/local/etc/nginx/nginx.conf` if you install it via `brew` or at `/usr/local/opt/nginx/conf/nginx.conf` if you manually compile it.

```bash
# /usr/local/etc/nginx/nginx.conf or /usr/local/opt/nginx/conf/nginx.conf

user eastagile staff; # change to current user
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include           mime.types;
    default_type      application/octet-stream;
    sendfile          on;
    keepalive_timeout 65;

    # get this from `passenger-config --root`
    passenger_root /usr/local/opt/passenger/libexec/lib/phusion_passenger/locations.ini;

    # get this from `passenger-config --ruby-command`
    passenger_ruby /Users/eastagile/.rvm/gems/ruby-2.1.5@eastagile-networking/wrappers/ruby;
    gzip  on;

    server {
        listen 80;
        server_name network.eastagile.vn localhost 127.0.0.1 192.168.1.39; # change to match your URL and static IP
        passenger_enabled on;
        root /Users/eastagile/code/production/EastAgile_networking/current/public;
        access_log /Users/eastagile/code/production/EastAgile_networking/current/log/nginx_access.log;
        error_log  /Users/eastagile/code/production/EastAgile_networking/current/log/nginx_error.log;
    }
}
```

#### Test `nginx` config

```bash
$ sudo nginx -t
nginx: the configuration file nginx.conf syntax is ok
nginx: configuration file nginx.conf test is successful
```

**Notice:** If you received:

```
nginx: [emerg] unknown directive "passenger_root" in nginx.conf
```

You need to manually [compile `nginx` with `passenger`](#method-2).

## Setup `mysql`

Skip this part if you already got `mysql` running.

### Install `mysql`

Install `mysql` with:

```bash
$ brew install mysql
```

### Start `mysql` at starup
You can have `launchd` start `mysql` at startup with:

```bash
$ mkdir -p ~/Library/LaunchAgents
$ ln -sfv /usr/local/opt/mysql/*.plist ~/Library/LaunchAgents
```

### Create `mysql`'s `root` password

If you don't have root access to `mysql`, you can create one by running an unprotected MySQL instance:

```bash
$ `brew --prefix mysql`/bin/mysqld_safe --skip-grant-tables --skip-networking
```

Now set the new root password:
```sql
mysql -u root
  mysql> UPDATE mysql.user SET password=PASSWORD('password here') WHERE user='root';
  mysql> exit
  Bye
```

Remember to kill your `mysqld_safe` instance before starting a new `mysql` server.

### Start `mysql`

```bash
$ mysql.server start
```

Or using `launchd`:

```bash
$ launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist
```

Try logging into `mysql` with:
```bash
$ mysql -u root -p
```

## Install `redis`
Our app runs background jobs with `sidekiq`, which needs `redis` to work. So install `redis` if you haven't:

```bash
$ brew install redis
```

## Passwordless `sudo`

You need to setup passwordless `sudo` for current user or the speed test scripts won't be able to switch gateways. To do so:

```bash
$ sudo visudo
password:

# add this line to the end of file
eastagile ALL=(ALL) NOPASSWD: ALL

# save and quit
```

**Notice:** it's a **tab** character between `eastagile` and `ALL`

Make sure it works:

```bash
$ sudo -k

$ sudo whoami
root

# No password is asked
```

## Enable `ssh` server

 1. Go to `System Preferences > Sharing > Remote Login > Only These Users > Add`. Choose your username, notice the connection string (e.g. `ssh eastagile@192.168.1.39`).
 2. Generate the `ssh` key pair and add it to `github`, following [this guide](https://help.github.com/articles/generating-ssh-keys/).
 3. Allow `ssh` access via private key by `cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys`

## Application config

We need to put our application specific configs into `~/code/production/EastAgile_networking/shared`, so create the folders:

```bash
$ mkdir -p ~/code/production/EastAgile_networking/shared{tmp,log,config}
```

Sample config files:

```yaml
# config/config.yml

production:
  host: '127.0.0.1'
```

```yaml
# config/database.yml

production:
  adapter: mysql2
  encoding: utf8
  database: ea_networking_production
  username: username
  password: password
  host: localhost
  port: 3306
```

```yaml
# config/secrets.yml

production:
  secret_key_base: randomkey
```

## Gateway config

If you want to change the gateway info, refer to `config/gateway.yml`.

```yaml
# config/gateway.yml

# Notice: this file is to be read into `bash` by a simple `yaml` parser, so keep its syntax basic. Also, keep the indentation at 2 spaces.

# Define the gateways that East Agile is using, together with their corresponding IPs
gateway:
  VNPT1: 192.168.1.2
  VIETTEL1: 192.168.1.1
  VIETTEL2: 192.168.1.3
  VIETTEL3: 192.168.1.4
  FPT1: 192.168.1.5

# The name of gateways to do speed test, in the order that we want to display them in our chart reports
# Notice: seperate the names by a *single space
gateways: VIETTEL1 VIETTEL2 VIETTEL3 FPT1 VNPT1

# This is the gateway that we will switch back to after the test, so that domain mapping for network.eastagile.vn works properly
default_gateway: VIETTEL1

# The static IP to assign to this machine when switching gateway
ip: 192.168.1.39
```

**Notice:** you need to push the change to this file to `github` in order for it to take effect.

## `Cronjob` config

We have `whenever` gem to setup `cronjob` for us using the settings found in `config/schedule.rb`.

By default this will run speed test every hour and start `nginx`, `redis` and `sidekiq` at startup. If you already have your service manager start any of these services, you can delete it here.

## Optional OS settings

**Notice:** this is optional. There are security issues with auto-login and not enabling *FileVault*.

Use these settings in *System Preferences* to automatically start the server after power failure.
```
System Preferences
  Energy Saver
    Disable computer sleep
    Lower display sleep
    Disable Put hard disks to sleep when possible
    Enable Wake for network access
    Enable Start up automatically after a power failure
  Security & Privacy
    FileVault
      Turn off FileVault (may need to restart OS)
    General
      Enable automatic login
  Users & Groups
    Enable automatic login as eastagile
```
# Development Machine Setup

These steps are meant for your **development** machine. You can develop right on your host machine though.

## Get the `ssh` key
Copy the private key from your host machine:

```bash
$ scp eastagile@192.168.1.39:~/.ssh/id_rsa ~/code/EastAgile_networking/server-ssh-key
```

`Chmod` for good:

```bash
chmod 400 ~/code/EastAgile_networking/server-ssh-key
```

Try the `ssh` connection:

```bash
ssh -i server-ssh-key eastagile@192.168.1.39
```

## Get the Source

Clone the source:

```bash
$ mkdir -p ~/code && cd ~/code

$ git clone https://github.com/EastAgile/EastAgile_networking.git

$ cd EastAgile_networking

$ git checkout -t origin/master
```

Make sure your `ruby version` and `ruby gemset` are correct:

```bash
$ cd .

$ rvm gemset list
gemsets for ruby-2.1.5 (found in /Users/eastagile/.rvm/gems/ruby-2.1.5)
   (default)
=> eastagile-networking
   global
```
Bundle:

```bash
bundle install
```

## Edit Deployment Host Target

Edit `config/deploy/production.rb` to match your host and username.

**Notice:** you don't have to push the changes to this file to `github`.

```ruby
# config/deploy/production.rb

# Common server-specific settings
set :primary_domain, '192.168.1.39' # change to your host IP
set :primary_user,   'eastagile'    # your host username

...

set :ssh_options, {
  keys: "server-ssh-key", # path to your ssh key
  forward_agent: true     # change this to `false` if you deploy locally
}
```

# Deployment Time!

On your development machine:

```bash
$ cap production deploy
```

Then, do a database seed on your host machine:

```bash
$ cd ~/code/production/EastAgile_networking/current

$ RAILS_ENV=production rake db:seed
```


----------
#### Previous Maintainers

 - Hoang Huynh • hoang.huynh@eastagile.com
 - Trang Ho • trang.ho@eastagile.com
 - Thao Chau • thao.chau@eastagile.com
