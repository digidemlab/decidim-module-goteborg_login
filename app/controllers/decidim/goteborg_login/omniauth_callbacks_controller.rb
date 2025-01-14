# frozen_string_literal: true

module Decidim
  module GoteborgLogin
    class OmniauthCallbacksController < ::Decidim::Devise::OmniauthRegistrationsController

      def dev_log(s) 
        Decidim::GoteborgLogin::Dbg.dev_log "--- omniauth_callbacks_controller.rb : #{s}"
      end

      # Make the view helpers available needed in the views
      helper Decidim::GoteborgLogin::Engine.routes.url_helpers
      helper_method :omniauth_registrations_path

      skip_before_action :verify_authenticity_token, only: [:goteborg_login, :failure]
      skip_after_action :verify_same_origin_request, only: [:goteborg_login, :failure]

      def gbgpub
        gbg_post_idp_auth :gbgpub
      end

      def gbgip 
        gbg_post_idp_auth :gbgip 
      end

      def localidp 
        gbg_post_idp_auth :localidp
      end

      def gbg_post_idp_auth(gbg_idp)

        session["decidim-goteborg_login.signed_in"] = true
        session["decidim-goteborg_login.gbg_idp"] = gbg_idp

        if (redirect_path = session[:saml_redirect_url]).present? && redirect_path.match?(%r{\A/[^/].*\z})
          store_location_for(:user, redirect_path)
        end

        authenticator.validate!

        if user_signed_in?
          
          # The user is most likely returning from an authorization request
          # because they are already signed in. In this case, add the
          # authorization and redirect the user back to the authorizations view.

          # Make sure the user has an identity created in order to aid future
          # Suomi.fi sign ins. In case this fails, it will raise a
          # Decidim::GoteborgLogin::Authentication::IdentityBoundToOtherUserError
          # which is handled below.
          authenticator.identify_user!(current_user)

          # Add the authorization for the user
          return fail_authorize unless authorize_user(current_user)

          # Forget user's "remember me"
          current_user.forget_me!
          cookies.delete :remember_user_token, domain: current_organization.host
          cookies.delete :remember_admin_token, domain: current_organization.host
          cookies.update response.cookies

          # Store the Suomi.fi session
          create_goteborg_login_session!

          # Show the success message and redirect back to the authorizations
          flash[:notice] = t(
            "authorizations.create.success",
            scope: "decidim.goteborg_login.verification"
          )
          return redirect_to(
            stored_location_for(resource || :user) ||
            decidim.root_path
          )
        end

        # Normal authentication request, proceed with Decidim's internal logic.
        send(:create)
      rescue Decidim::GoteborgLogin::Authentication::ValidationError => e
        fail_authorize(e.validation_key)
      rescue Decidim::GoteborgLogin::Authentication::IdentityBoundToOtherUserError
        fail_authorize(:identity_bound_to_other_user)
      end

      # Overridden so that we can store the
      def sign_in(resource_or_scope, *args)
        super

        # Check that this is coming from the Decidim authentication
        options = args.extract_options!
        return unless options
        return if options[:event] != :authentication

        create_goteborg_login_session!
      end

      def failure
        strategy = failed_strategy
        saml_response = strategy.response_object if strategy
        return super unless saml_response

        # In case we want more info about the returned status codes, use the
        # code below.
        #
        # Status codes:
        #   Requester = A problem with the request OR the user cancelled the
        #               request at the identity provider.
        #   Responder = The handling of the request failed.
        #   VersionMismatch = Wrong version in the request.
        #
        # Additional state codes:
        #   AuthnFailed = The authentication failed OR the user cancelled
        #                 the process at the identity provider.
        #   RequestDenied = The authenticating endpoint (which the
        #                   identity provider redirects to) rejected the
        #                   authentication.
        # if !saml_response.send(:validate_success_status) && !saml_response.status_code.nil?
        #   codes = saml_response.status_code.split(" | ").map do |full_code|
        #     full_code.split(":").last
        #   end
        # end

        # Some extra validation checks
        validations = [
          # The success status validation fails in case the response status
          # code is something else than "Success". This is most likely because
          # of one the reasons explained above. In general there are few
          # possible explanations for this:
          # 1. The user cancelled the request and returned to the service.
          # 2. The underlying identity service the IdP redirects to rejected
          #    the request for one reason or another. E.g. the user cancelled
          #    the request at the identity service.
          # 3. There is some technical problem with the identity provider
          #    service or the XML request sent to there is malformed.
          :success_status,
          # Checks if the local session should be expired, i.e. if the user
          # took too long time to go through the authorization endpoint.
          :session_expiration,
          # The NotBefore and NotOnOrAfter conditions failed, i.e. whether the
          # request is handled within the allowed timeframe by the IdP.
          :conditions
        ]
        validations.each do |key|
          next if saml_response.send("validate_#{key}")

          flash[:alert] = t(".#{key}")
          return redirect_to after_omniauth_failure_path_for(resource_name)
        end

        super
      end

      # This is overridden method from the Devise controller helpers
      # This is called when the user is successfully authenticated which means
      # that we also need to add the authorization for the user automatically
      # because a succesful Suomi.fi authentication means the user has been
      # successfully authorized as well.
      def sign_in_and_redirect(resource_or_scope, *args)
        # Add authorization for the user
        if resource_or_scope.is_a?(::Decidim::User)
          result = authorize_user(resource_or_scope)
          return fail_authorize unless result
        end

        super
      end

      # Disable authorization redirect for the first login
      def first_login_and_not_authorized?(_user)
        false
      end

      private

      def authorize_user(user)
        authenticator.authorize_user!(user)
      rescue Decidim::GoteborgLogin::Authentication::AuthorizationBoundToOtherUserError
        nil
      end

      def create_goteborg_login_session!
        Decidim::GoteborgLogin::Session.create!(
          user: current_user,
          saml_uid: session["saml_uid"],
          saml_session_index: session["saml_session_index"]
        )
      end

      def fail_authorize(failure_message_key = :already_authorized)
        flash[:alert] = t(
          "failure.#{failure_message_key}",
          scope: "decidim.goteborg_login.omniauth_callbacks"
        )

        redirect_path = stored_location_for(resource || :user) || decidim.root_path
        if session.delete("decidim-goteborg_login.signed_in")
          params = "?RelayState=#{CGI.escape(redirect_path)}"

          # FIXME: Verify this failure path, see lib/decidim/goteborg_login/authentication/authenticator.rb and validate!
          # I don't understand the magic that create the user_..._login_omniauth_spslo_path
          return redirect_to user_localidp_login_omniauth_spslo_path + params
        end

        redirect_to redirect_path
      end

      # Needs to be specifically defined because the core engine routes are not
      # all properly loaded for the view and this helper method is needed for
      # defining the omniauth registration form's submit path.
      def omniauth_registrations_path(resource)
        Decidim::Core::Engine.routes.url_helpers.omniauth_registrations_path(resource)
      end

      # Private: Create form params from omniauth hash
      # Since we are using trusted omniauth data we are generating a valid signature.
      def user_params_from_oauth_hash
        authenticator.user_params_from_oauth_hash
      end

      def authenticator

        # @authenticator ||= Decidim::GoteborgLogin.authenticator_for(
        @authenticator ||= Decidim::GoteborgLogin.authenticator_for(
          current_organization,
          oauth_hash
        )
      end

      def verified_email
        authenticator.verified_email
      end
    end
  end
end
