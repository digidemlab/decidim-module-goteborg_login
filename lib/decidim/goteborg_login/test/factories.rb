# frozen_string_literal: true

require "decidim/components/namer"
require "decidim/core/test/factories"

FactoryBot.define do
  factory :goteborg_login_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :goteborg_login).i18n_name }
    manifest_name :goteborg_login
    participatory_space { create(:participatory_process, :with_steps) }
  end

  # Add engine factories here
end
