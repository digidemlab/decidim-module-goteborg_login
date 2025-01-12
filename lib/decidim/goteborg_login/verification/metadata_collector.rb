# frozen_string_literal: true

module Decidim
  module GoteborgLogin
    module Verification
      class MetadataCollector
        def initialize(saml_attributes)
          @saml_attributes = saml_attributes
        end

        def metadata
          first_name = saml_attributes[:first_names]
          last_name = saml_attributes[:last_name]
          given_name = saml_attributes[:given_name]

          eidas = false
          if saml_attributes[:eidas_person_identifier]
            eidas = true
            first_name = saml_attributes[:eidas_first_names]
            last_name = saml_attributes[:eidas_family_name]
          end

          {
            eidas:,
            pin_digest: person_identifier_digest,
            # The first name will contain all first names of the person
            first_name:,
            # The given name is the primary first name of the person, also known
            # as "calling name" (kutsumanimi).
            given_name:,
            last_name:,
          }
        end

        # Digested format of the person's identifier unique to the person. The
        # digested format is used because the undigested format may hold
        # personal sensitive information about the user and may require special
        # care regarding the privacy policy. These will still be unique hashes
        # bound to the person's identification number.
        def person_identifier_digest
          @person_identifier_digest ||= begin
            prefix = nil
            pin = nil

            if saml_attributes[:personal_identity_number]
              prefix = "SV"
              pin = saml_attributes[:personal_identity_number]
            elsif saml_attributes[:eidas_person_identifier]
              prefix = "EIDAS"
              pin = saml_attributes[:eidas_person_identifier]
            end

            if prefix && pin
              Digest::MD5.hexdigest(
                "#{prefix}:#{pin}:#{Rails.application.secrets.secret_key_base}"
              )
            end
          end
        end

        protected

        attr_reader :saml_attributes
      end
    end
  end
end
