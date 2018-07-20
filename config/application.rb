# frozen_string_literal: true

require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
#require "active_model/railtie"
#require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
#require "action_mailer/railtie"
#require "action_view/railtie"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Workaround for debify not being able to use embedded gems.
$LOAD_PATH.push File.expand_path "../../engines/conjur_audit/lib", __FILE__
require 'conjur_audit'

module Possum
  class Application < Rails::Application
ROOT_PATH = File.expand_path('..', File.dirname(__FILE__))

def require_with_reload_check(raw_path)

  unless $LOADED_FEATURES.include?(raw_path)
    $require_sites ||= {}
    site, line, info = caller.first.split(':')
    expanded_site = File.expand_path(site)
    load_dir = $LOAD_PATH.detect{|dir|
      File.exist?(File.expand_path(raw_path + ".rb", dir))
    }
    expanded_path = File.expand_path(raw_path, load_dir)

    if (expanded_path.index(ROOT_PATH) == 0) &&
        $require_sites.key?(expanded_path) &&
        $require_sites[expanded_path][:as] != raw_path &&
        expanded_path !~ /test_helper$/
      warn "!" * 80
      warn "#{expanded_path} is being reloaded!"
      warn "It was originally loaded as: #{$require_sites[expanded_path][:as]}"
      warn "From #{$require_sites[expanded_path][:in]}"
      warn "But now it is being loaded as: #{raw_path}"
      warn "In #{expanded_site}"
      warn "!" * 80
    end

    $require_sites[expanded_path] = {
      :as => raw_path,
      :in => expanded_site
    }
  end
end

unless defined?($reload_guard_enabled)
  alias require_without_reload_check require
  alias require require_with_reload_check
  $reload_guard_enabled = true
end
    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths << Rails.root.join('lib')


    config.sequel.after_connect = proc do
      Sequel.extension :core_extensions, :postgres_schemata
    end

    config.encoding = "utf-8"
    config.active_support.escape_html_entities_in_json = true

    # Whether to dump the schema after successful migrations.
    # Defaults to false in production and test, true otherwise.
    config.sequel.schema_dump = false

    # Token authentication is optional for authn routes, and it's not applied at all to authentication.
    config.middleware.use Conjur::Rack::Authenticator,
      optional: [
        /^\/authn-[^\/]+\//,
        /^\/authn\//,
        /^\/public_keys\//
      ],
      except: [
        /^\/authn-[^\/]+\/.*\/authenticate$/,
        /^\/authn\/.*\/authenticate$/,
        /^\/host_factories\/hosts$/,
        /^\/assets\/.*/,
        /^\/authenticators$/,
        /^\/$/
      ]
  end
end
