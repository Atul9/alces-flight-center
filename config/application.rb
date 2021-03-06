require_relative 'boot'

require "rails"

# Require just the parts of Rails we use.
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AlcesFlightCenter
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Use our local time zone whenever we work with/display times in app; no
    # matter where users are we want to use and for them to see the schedule
    # that we operate on.
    config.time_zone = 'London'

    # Still save everything in UTC; should make things more straightforward if
    # we ever want to handle times in other time zones in future.
    config.active_record.default_timezone = :utc

    config.email_bcc_address = ENV['EMAIL_BCC_ADDRESS'] || 'tickets@alces-software.com'

    config.active_job.queue_adapter = :resque

    config.email_from = if ENV['STAGING']
                          'Alces Flight Center Staging <center+staging@alces-flight.com>'
                        else
                          'Alces Flight Center <center@alces-flight.com>'
                        end

    # Handle Pundit authorization failure as 403 (forbidden) - see
    # https://github.com/varvet/pundit/blob/dc7095118c47faca1fbea213f8b82d4d0b2616a0/README.md#rescuing-a-denied-authorization-in-rails.
    config.action_dispatch.rescue_responses['Pundit::NotAuthorizedError'] = :forbidden

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.exceptions_app = self.routes
  end
end
