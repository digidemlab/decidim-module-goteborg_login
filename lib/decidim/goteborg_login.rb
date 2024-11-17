# frozen_string_literal: true

require "omniauth"

# Make sure the omniauth methods work after OmniAuth 2.0+
require "omniauth/rails_csrf_protection"

require "decidim/goteborg_login/admin"
require "decidim/goteborg_login/engine"
require "decidim/goteborg_login/admin_engine"
require "decidim/goteborg_login/component"

require "omniauth/strategies/gbgpub_strategy"
require "omniauth/strategies/gbgip_strategy"
require "omniauth/strategies/localidp_strategy"

require_relative "goteborg_login/authentication/authenticator"
require_relative "goteborg_login/authentication/errors"
require_relative "goteborg_login/verification/metadata_collector"
require_relative "goteborg_login/verification/manager"

require_relative "goteborg_login_dbg"
require_relative "goteborg_login_gbgpub"
require_relative "goteborg_login_gbgip"
require_relative "goteborg_login_localidp"



module Decidim
  # This namespace holds the logic of the `GoteborgLogin` component. This component
  # allows users to create goteborg_login in a participatory space
  module GoteborgLogin
    include ActiveSupport::Configurable

    @configured = false

    # Allows customizing parts of the authentication flow such as validating
    # the authorization data before allowing the user to be authenticated.
    config_accessor :authenticator_class do
      Decidim::GoteborgLogin::Authentication::Authenticator
    end

    # Allows customizing how the authorization metadata gets collected from
    # the SAML attributes passed from the authorization endpoint.
    config_accessor :metadata_collector_class do
      Decidim::GoteborgLogin::Verification::MetadataCollector
    end

    def self.configured?
      @configured
    end

    def self.configure
      @configured = true
      super
    end

    def self.authenticator_for(organization, oauth_hash)
      Decidim::GoteborgLogin::Authentication::Authenticator.new(organization, oauth_hash)
    end
  end
end
