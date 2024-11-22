# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module GoteborgLogin
    
    # This is the engine that runs on the public interface of goteborg_login.
    class Engine < ::Rails::Engine

      isolate_namespace Decidim::GoteborgLogin

      routes do
        # Add engine routes here
        # resources :goteborg_login
        # root to: "goteborg_login#index"

        devise_scope :user do
          # Manually map the SAML omniauth routes for Devise because the default
          # routes are mounted by core Decidim. This is because we want to map
          # these routes to the local callbacks controller instead of the
          # Decidim core.
          # See: https://git.io/fjDz1
          

          # NOTE: Important that the urls are '/users/auth/<idp>/callback' due to omniauth magic...
          
          # match(
          #   "/users/auth/gbgpub",
          #   to: "omniauth_callbacks#passthru",
          #   as: "user_gbgpub_omniauth_authorize",
          #   via: [:get, :post]
          # )
          
          # match(
          #   "/users/auth/localidp",
          #   to: "omniauth_callbacks#passthru",
          #   as: "user_localidp_omniauth_authorize",
          #   via: [:get, :post]
          # )


          # -- callback

          match(
            "/users/auth/gbgpub/callback",
            to: "omniauth_callbacks#gbgpub",
            as: "user_gbgpub_omniauth_callback",
            via: [:get, :post]
          )

          match(
            "/users/auth/gbgip/callback",
            to: "omniauth_callbacks#gbgip",
            as: "user_gbgipomniauth_callback",
            via: [:get, :post]
          )

          match(
            "/users/auth/localidp/callback",
            to: "omniauth_callbacks#localidp",
            as: "user_localidp_omniauth_callback",
            via: [:get, :post]
          )

          # -- slo

          match(
            "/users/auth/gbgpub/slo",
            to: "sessions#slo",
            as: "user_gbgpub_omniauth_slo",
            via: [:get, :post]
          )

          match(
            "/users/auth/gbgip/slo",
            to: "sessions#slo",
            as: "user_gbgip_omniauth_slo",
            via: [:get, :post]
          )

          match(
            "/users/auth/localidp/slo",
            to: "sessions#slo",
            as: "user_localidp_omniauth_slo",
            via: [:get, :post]
          )

          # -- spslo

          match(
            "/users/auth/gbgpub/spslo",
            to: "sessions#spslo",
            as: "user_gbgpub_omniauth_spslo",
            via: [:get, :post]
          )

          match(
            "/users/auth/gbgip/spslo",
            to: "sessions#spslo",
            as: "user_gbgip_omniauth_spslo",
            via: [:get, :post]
          )

          match(
            "/users/auth/localidp/spslo",
            to: "sessions#spslo",
            as: "user_localidp_omniauth_spslo",
            via: [:get, :post]
          )


          # Manually map the sign out path in order to control the sign out
          # flow through OmniAuth when the user signs out from the service.
          # In these cases, the user needs to be also signed out from Suomi.fi
          # which is handled by the OmniAuth strategy.
          match(
            "/users/sign_out",
            to: "sessions#destroy",
            as: "destroy_user_session",
            via: [:delete, :post]
          )

          # This is the callback route after a returning from a successful sign
          # out request through OmniAuth.
          match(
            "/users/slo_callback",
            to: "sessions#slo_callback",
            as: "slo_callback_user_session",
            via: [:get]
          )
        end

      end

      initializer "GoteborgLogin.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end


      initializer "decidim_goteborg_login.mount_routes", before: :add_routing_paths do
        # Mount the engine routes to Decidim::Core::Engine because otherwise
        # they would not get mounted properly. Note also that we need to prepend
        # the routes in order for them to override Decidim's own routes for the
        # goteborg authentication.
        Decidim::Core::Engine.routes.prepend do
          mount Decidim::GoteborgLogin::Engine => "/"
        end
      end

      initializer "decidim_goteborg_login.setup", before: "devise.omniauth" do
        # Configure the SAML OmniAuth strategy for Devise
        
        if Decidim::GoteborgLogin::Gbgpub.configured? 
          ::Devise.setup do |config|
            config.omniauth(
              :gbgpub,
              Decidim::GoteborgLogin::Gbgpub.omniauth_settings
            )
          end
        end

        if Decidim::GoteborgLogin::Gbgip.configured? 
          ::Devise.setup do |config|
            config.omniauth(
              :gbgip,
              Decidim::GoteborgLogin::Gbgip.omniauth_settings
            )
          end
        end


        if Decidim::GoteborgLogin::Localidp.configured? 
          ::Devise.setup do |config|
            config.omniauth(
              :localidp,
              Decidim::GoteborgLogin::Localidp.omniauth_settings
            )
          end
        end


        # Customized version of Devise's OmniAuth failure app in order to handle
        # the failures properly. Without this, the failure requests would end
        # up in an ActionController::InvalidAuthenticityToken exception.

        devise_failure_app = OmniAuth.config.on_failure
        OmniAuth.config.on_failure = proc do |env|
          if env["PATH_INFO"].match?(%r{^/users/auth/gbg(/.*)?})
            env["devise.mapping"] = ::Devise.mappings[:user]
            Decidim::GoteborgLogin::OmniauthCallbacksController.action(
              :failure
            ).call(env)
          else
            # Call the default for others.
            devise_failure_app.call(env)
          end
        end
      end
    end
  end
end
