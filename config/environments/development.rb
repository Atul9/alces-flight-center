Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Using eager loading in development would be nice, to match production and
  # catch loading problems early (see https://stackoverflow.com/a/40019108),
  # but is causing issues at the moment (see
  # https://stackoverflow.com/questions/44465118).
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Host to use when generating URls in emails.
  config.action_mailer.default_url_options = { host: 'localhost:3000' }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Alces Flight Center custom config.
  config.rt_interface_class = FakeRequestTrackerInterface.to_s

  # Set up Bullet Gem
  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
    # XXX Consider adding this.
    # Bullet.slack = { webhook_url: 'http://some.slack.url', channel: '#alces-flight-center', username: 'bob' }

    [:cluster, :component, :service].each do |association|
      Bullet.add_whitelist type: :unused_eager_loading,
        class_name: 'Case',
        association: association
    end

    ['Component', 'Service'].each do |model|
      Bullet.add_whitelist type: :unused_eager_loading,
        class_name: model,
        association: :cluster
      # Bullet.add_whitelist type: :unused_eager_loading,
      #   class_name: model,
      #   association: :maintenance_windows
    end
  end
end
