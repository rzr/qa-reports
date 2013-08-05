Meegoqa::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # Configure exception notifications
  exception_notifier_config_file_path = File.expand_path('../../exception_notifier', __FILE__)
  email_addresses = eval File.open(exception_notifier_config_file_path).gets if File.exist?(exception_notifier_config_file_path)

  config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => "[MeeGo QA Reports] ",
      :sender_address => %{"Exception Notifier" <notifier@qa-reports.meego.com>},
      :exception_recipients => email_addresses
    }

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # TODO: Needs to be configured in nginx
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # config.action_mailer.default_url_options = {
  #   host: 'yourdomain.com'
  # }
  # config.action_mailer.delivery_method = :smtp
  # ActionMailer::Base.smtp_settings = {
  #   address: 'smtp.yourdomain.com', port: 25
  # }

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Set the digests to precompiled assets
  config.assets.digest = true
  # Compress JS
  config.assets.compress = true

  # Enable the below settings if you have SSL enabled server to force
  # login and related actions to happen over SSL. If using nginx you need
  # to set proxy_set_header X_FORWARDED_PROTO $scheme; to site configuration.
  # In addition the SSL and non-SSL servers must be separately defined and
  # SSL needs to be enabled with the legacy format "ssl on;"
  #   https://github.com/plataformatec/devise/wiki/How-To:-Use-SSL-(HTTPS)

  #config.to_prepare { Devise::SessionsController.force_ssl }
  #config.to_prepare { Devise::RegistrationsController.force_ssl }
  #config.to_prepare { Devise::PasswordsController.force_ssl }
end
