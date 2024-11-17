# frozen_string_literal: true

module Decidim
  module GoteborgLogin
    # This is the engine that runs on the public interface of `GoteborgLogin`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::GoteborgLogin::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        # resources :goteborg_login do
        #   collection do
        #     resources :exports, only: [:create]
        #   end
        # end
        # root to: "goteborg_login#index"
      end

      def load_seed
        nil
      end
    end
  end
end
