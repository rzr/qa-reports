# Must be set before requireing multisage
set :default_stage, "staging"
set :application, "qa-reports"
require 'capistrano/ext/multistage'
require './config/deploy/capistrano_database_yml'
require 'bundler/capistrano'
require 'yaml'
require "rvm/capistrano"
set :rvm_ruby_string, '1.9.3'
set :rvm_type, :user

set :user, "www-data"
set :use_sudo, false
set :copy_compression, :zip

set :scm, :git
set :repository, "http://github.com/leonidas/qa-reports.git"

ssh_options[:forward_agent] = true

after "deploy:setup" do
  # Create shared directories
  run "mkdir -p #{shared_path}/config"
  run "mkdir -p #{shared_path}/reports"
  run "mkdir -p #{shared_path}/files"
  run "mkdir -p #{shared_path}/reports/tmp"

  # Create newrelic configuration file
  enable_newrelic = Capistrano::CLI::ui.ask("Do you want to enable NewRelic performance monitoring? Please note this sends data to external service. Default: no")
  newrelic_config = YAML.load_file("config/newrelic.yml")
  if enable_newrelic =~ /yes/i
    newrelic_config["production"]["monitor_mode"] = true
    newrelic_config["staging"]["monitor_mode"] = true
  end
  put YAML::dump(newrelic_config), "#{shared_path}/config/newrelic.yml"

  # Create registeration token
  registeration_token = Capistrano::CLI::ui.ask("What registeration token you want to use? (/users/<token>/register). Default: none")
  put registeration_token, "#{shared_path}/config/registeration_token"

  # Create Exception Notifier email list
  email_addresses = Capistrano::CLI::ui.ask("Which email addresses should be notified in case of application errors? (Space separated list of email addresses)")
  put "%w{#{email_addresses}}", "#{shared_path}/config/exception_notifier"

  # Bugzilla configuration - only HTTP auth
  bugzilla_conf      = YAML.load_file("config/bugzilla.yml")
  bugzilla_http_auth = Capistrano::CLI::ui.ask("Do you want to define HTTP credentials to access Bugzilla? Note that you should have a separate user account for this since the credentials are stored as plain text. Default: No")
  if bugzilla_http_auth =~ /yes/i
    bugzilla_uname = Capistrano::CLI::ui.ask("Please enter your HTTP username")
    bugzilla_passw = Capistrano::CLI::ui.ask("Please enter your HTTP password")
    bugzilla_conf["http_username"] = bugzilla_uname
    bugzilla_conf["http_password"] = bugzilla_passw
  end
  bugzilla_auth = Capistrano::CLI::ui.ask("Do you want to define Bugzilla credentials? Note that you should have a separate user account for this since the credentials are stored as plain text. Default: No")
  if bugzilla_auth =~ /yes/i
    bugzilla_uname = Capistrano::CLI::ui.ask("Please enter your Bugzilla username")
    bugzilla_passw = Capistrano::CLI::ui.ask("Please enter your Bugzilla password")
    bugzilla_conf["bugzilla_username"] = bugzilla_uname
    bugzilla_conf["bugzilla_password"] = bugzilla_passw
  end
  put YAML::dump(bugzilla_conf), "#{shared_path}/config/bugzilla.yml"

  # Upload application config
  upload("config/config.yml", "#{shared_path}/config/config.yml")

  # Upload QA Dashboard configuration
  deploy.qadashboard.setup
end

after "deploy:update_code" do
  # Remove default QA Dashboard config and symlink to shared.
  run "rm #{latest_release}/config/qa-dashboard_config.yml"
  run "ln -nfs #{shared_path}/config/qa-dashboard_config.yml #{latest_release}/config/qa-dashboard_config.yml"

  # Remove local directories
  run "rm -fr #{latest_release}/public/reports"

  # Link to shared folders
  run "ln -nfs #{shared_path}/reports #{latest_release}/public/"
  run "ln -nfs #{shared_path}/files #{latest_release}/public/"
end

after "deploy:create_symlink" do
  # Remove empty token file that comes with deployment and symlink to shared
  run "rm -rf #{current_path}/config/registeration_token"
  run "ln -nfs #{shared_path}/config/registeration_token #{current_path}/config/registeration_token"

  # Remove current newrelic config file and symlink to shared
  run "rm #{current_path}/config/newrelic.yml"
  run "ln -nfs #{shared_path}/config/newrelic.yml #{current_path}/config/newrelic.yml"

  # Symlink exception notifier config to shared
  run "ln -nfs #{shared_path}/config/exception_notifier #{current_path}/config/exception_notifier"

  # Remove current bugzilla config file and symlink to shared
  run "rm #{current_path}/config/bugzilla.yml"
  run "ln -nfs #{shared_path}/config/bugzilla.yml #{current_path}/config/bugzilla.yml"

  # Remove current app config file and symlink to shared
  run "rm #{current_path}/config/config.yml"
  run "ln -nfs #{shared_path}/config/config.yml #{current_path}/config/config.yml"
end

namespace :deploy do
  desc "Deploy new version of config.yml"
  task :app_settings, :roles => :app do
    # https://gist.github.com/mrchrisadams/3084229/#comment-575046
    top.upload("config/config.yml", "#{shared_path}/config/config.yml")
  end

  desc "Restart the app server"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Start the app server"
  task :start, :roles => :app do
    run "passenger start #{current_path} --daemonize --environment #{rails_env} --port 3000"
  end

  desc "Stop the app server"
  task :stop, :roles => :app do
    run "passenger stop --pid-file #{current_path}/passenger.3000.pid"
  end

  desc "Create logrotate config"
  task :logrotate, :roles => :app do
    conf = IO.read("config/logrotate.conf")
    conf["##SHARED_PATH##"] = shared_path
    # Write to shared path
    put conf, "#{shared_path}/config/logrotate.conf"
    write_file = Capistrano::CLI::ui.ask("Write logrotate conf to /etc/logrotate.d (needs passwordless sudo)? Default:no")
    if write_file =~ /yes/i
      run "cat #{shared_path}/config/logrotate.conf | sudo /usr/bin/tee /etc/logrotate.d/qa-reports"
    else
      puts "Logrotate config written to #{shared_path}/config/logrotate.conf on remote server. Copy to /etc/logrotate.d by yourself."
    end
  end

  namespace :qadashboard do
    desc "Upload QA Dashboard configuration"
    task :setup do
      # QA Dashboard configuration
      qadashboard_conf = YAML.load_file("config/qa-dashboard_config.yml")
      qadashboard_auth = Capistrano::CLI::ui.ask("Do you want to define configuration for automatic report exporting to QA Dashboard? Default: No")
      if qadashboard_auth =~ /yes/i
        qadashboard_host  = Capistrano::CLI::ui.ask("Please enter QA Dashboard URL (e.g. http://localhost:3030)")
        qadashboard_token = Capistrano::CLI::ui.ask("Please enter authentication token for report upload")
        qadashboard_conf["host"]  = qadashboard_host
        qadashboard_conf["token"] = qadashboard_token
      end
      put YAML::dump(qadashboard_conf), "#{shared_path}/config/qa-dashboard_config.yml"
    end

    desc "Remove default QA Dashboard config and symlink to shared."
    task :symlink do
      run "rm #{current_path}/config/qa-dashboard_config.yml"
      run "ln -nfs #{shared_path}/config/qa-dashboard_config.yml #{current_path}/config/qa-dashboard_config.yml"
    end

    desc "Update QA Dashboard configuration"
    task :update do
      deploy.qadashboard.setup
      deploy.qadashboard.symlink
      deploy.restart
    end
  end
end
