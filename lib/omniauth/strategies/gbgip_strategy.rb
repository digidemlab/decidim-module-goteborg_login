
require 'omniauth-saml'


module OmniAuth
  module Strategies
    class Gbgip < SAML
      def dev_log(s)
        Decidim::GoteborgLogin::Dbg.dev_log "... gbgip_strategy.rb : #{s}"
      end

      # Add the SAML attributes and the VTJ search success state to the extra
      # hash for easier access.
      extra do
        {
          saml_attributes: saml_attributes
        }
      end

      attr_accessor :options
      attr_reader :gbgip_thread

      # rubocop:disable Metrics/MethodLength
      def initialize(app, *args, &block)
        super
        dev_log "initialize : 10 :"

        options[:sp_name_qualifier] = options[:sp_entity_id] if options[:sp_name_qualifier].nil?

        # Remove the nil options from the original options array that will be
        # defined by the Suomi.fi options
        %i[
          certificate
          private_key
          idp_name_qualifier
          name_identifier_format
          security
        ].each do |key|
          options.delete(key) if options[key].nil?
        end

        # Add the Suomi.fi options to the local options, most of which are
        # fetched from the metadata. The options array is the one that gets
        # priority in case it overrides some of the metadata or locally defined
        # option values.
        @gbgip_thread = Thread.new do
          @options = OmniAuth::Strategy::Options.new(
            gbgip_options.merge(options)
          )
        end
      end

      # Override the request phase to be able to pass the locale parameter to
      # the redirect URL. Note that this needs to be the last parameter to
      # be passed to the redirect URL.
      def request_phase
        dev_log "request_phase : 00 :"
        gbgip_thread.join if gbgip_thread.alive?
        dev_log "request_phase : 10 :"

        authn_request = OneLogin::RubySaml::Authrequest.new

        dev_log "request_phase : 20 :"
        session['saml_redirect_url'] = request.params['redirect_url']
        dev_log "request_phase : 30 : session=#{session}"

        with_settings do |settings|
          dev_log "request_phase : 35 :"

          url = authn_request.create(settings, additional_params_for_authn_request)

          dev_log "request_phase : 40 : url='#{url}'"

          redirect(url)
        end
    end

       # The request attributes for Suomi.fi
       option :possible_request_attributes, [
      ]

      option(
        :security_settings,
        authn_requests_signed: true,
        logout_requests_signed: true,
        logout_responses_signed: true,
        want_assertions_signed: true,
        digest_method: XMLSecurity::Document::SHA256,
        signature_method: XMLSecurity::Document::RSA_SHA256
      )

      option(
        :saml_attributes_map,
        display_name: ['urn:oid:2.16.840.1.113730.3.1.241'],
        given_name: ['urn:oid:2.5.4.42'],
        last_name: ['urn:oid:2.5.4.4'],
        email: ['urn:oid:0.9.2342.19200300.100.1.3'],
        personal_identity_number: ['urn:oid:1.2.752.29.4.13']
      )

      def scoped_request_attributes
        scopes = [:limited]
        scopes << :medium_extensive if options.scope_of_data == :medium_extensive
        scopes << :medium_extensive if options.scope_of_data == :extensive
        scopes << :extensive if options.scope_of_data == :extensive

        names = options.scoped_attributes.select do |key, _v|
          scopes.include?(key.to_sym)
        end.values.flatten

        options.possible_request_attributes.select do |attr|
          names.include?(attr[:name])
        end
      end

      def certificate
        File.read(options.certificate_file) if options.certificate_file
      end

      def private_key
        File.read(options.private_key_file) if options.private_key_file
      end

      def idp_metadata
        File.read(options.idp_metadata_file)
      end


      # rubocop:disable Metrics/MethodLength
      def gbgip_options
        idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new

        # Returns OneLogin::RubySaml::Settings prepopulated with idp metadata
        # We are using the redirect binding for the SSO and SLO URLs as these
        # are the ones expected by omniauth-saml. Otherwise the default would be
        # the first one defined in the IdP metadata, which would be the
        # HTTP-POST binding.
        settings = idp_metadata_parser.parse_to_hash(
          idp_metadata,
          sso_binding: ['urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'],
          slo_binding: ['urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect']
        )

        if settings[:idp_slo_response_service_url].nil? && settings[:idp_slo_target_url].nil?
          # Mitigation after ruby-saml update to 1.12.x. This gem has been
          # originally developed relying on the `:idp_slo_target_url` settings
          # which was removed from the newer versions. The SLO requests won't
          # work unless `:idp_slo_response_service_url` is defined in the
          # metadata through the `ResponseLocation` attribute in the
          # `<SingleLogoutService />` node.
          settings[:idp_slo_target_url] ||= settings[:idp_slo_service_url]
        end

        # Local certificate and private key to decrypt the responses
        settings[:certificate] = certificate
        settings[:private_key] = private_key

        # Define the security settings as there are some defaults that need to be
        # modified
        security_defaults = OneLogin::RubySaml::Settings::DEFAULTS[:security]
        settings[:security] = security_defaults.merge(options.security_settings)

        # Add some extra information that is necessary for correctly formatted
        # logout requests.
        settings[:idp_name_qualifier] = settings[:idp_entity_id]

        settings
      end
      # rubocop:enable Metrics/MethodLength

      def saml_attributes
        {}.tap do |attrs|
          options.saml_attributes_map.each do |target, source|
            attrs[target] = find_attribute_by(source)
          end
        end
      end

    end
  end
end
