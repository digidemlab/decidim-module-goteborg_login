# frozen_string_literal: true

module Decidim
  module GoteborgLogin
    module Verification
      class Manager
        def self.configure_workflow(workflow)
          Decidim::GoteborgLogin.workflow_configurator.call(workflow)
        end

        def self.metadata_collector_for(saml_attributes)
          Decidim::GoteborgLogin.metadata_collector_class.new(saml_attributes)
        end
      end
    end
  end
end
