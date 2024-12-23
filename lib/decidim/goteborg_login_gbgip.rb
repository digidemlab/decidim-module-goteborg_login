module Decidim
  module GoteborgLogin
    module Gbgip
      include ActiveSupport::Configurable

      @configured = false

      # :production, :development, :test
      config_accessor :mode, instance_reader: false

      # :limited - Limited scope
      # :medium_extensive - Medium-extensive scope
      # :extensive - Extensive scope
      # config_accessor :scope_of_data do
      #   :medium_extensive
      # end

      config_accessor :sp_entity_id, instance_reader: false

      # The certificate string for the application
      config_accessor :certificate, instance_reader: false

      # The private key string for the application
      config_accessor :private_key, instance_reader: false

      # The certificate file for the application
      config_accessor :certificate_file

      # The private key file for the application
      config_accessor :private_key_file


      def self.configured?
        @configured
      end

      def self.configure
        @configured = true
        super
      end

      def self.sp_entity_id
        return config.sp_entity_id if config.sp_entity_id
        raise "Missing Gbgip sp_entity_id configuration"
      end

      def self.assertion_consumer_service_url
        return config.assertion_consumer_service_url if config.assertion_consumer_service_url
        raise "Missing Gbgip assertion_consumer_service_url configuration"
      end

      def self.idp_metadata_file
        if config.idp_metadata_file
          return config.idp_metadata_file if File.exist?(config.idp_metadata_file)
          raise "Gbgip idp_metadata_file '#{config.idp_metadata_file}' doesn't exist!"
        else
          raise "Missing Gbgip idp_metadata_file configuration!"
        end
      end

      # The certificate string for the localidp
      config_accessor :certificate, instance_reader: false

      # The private key string for the localidp
      config_accessor :private_key, instance_reader: false

      # Defines how the session gets cleared when the OmniAuth strategy logs the
      # user out. This has been customized to preserve the flash messages in the
      # session after the session is destroyed.
      config_accessor :idp_slo_session_destroy do
        proc do |_env, session|
          flash = session["flash"]
          redirect_url = session["saml_redirect_url"]
          result = session.clear
          session["flash"] = flash if flash
          session["saml_redirect_url"] = redirect_url if redirect_url
          result
        end
      end

      def self.certificate
        if certificate_file
          return File.read(certificate_file) if File.exist?(certificate_file)
          raise "Gbgip certificate_file '#{certificate_file}' doesn't exist!"
        else
          raise "Missing Gbgip certificate_file configuration!"
        end
      end

      def self.private_key
        if private_key_file
          return File.read(private_key_file) if File.exist?(private_key_file)
          raise "Gbgip private_key_file '#{certificate_file}' doesn't exist!"
        else
          raise "Missing Gbgip private_key_file configuration!"
        end
       end

      def self.omniauth_settings
        settings = {
          mode:,
          # scope_of_data:,
          sp_entity_id:,
          assertion_consumer_service_url:,
          idp_metadata_file:,
          certificate:,
          private_key:,
          idp_slo_session_destroy:
        }
        settings.merge!(config.extra) if config.extra.is_a?(Hash)
        settings
      end

    end
  end
end

