# frozen_string_literal: true

namespace :decidim do
  namespace :goteborg_login do
    desc "Copy pin digest from metadata to its own column"
    task copy_pin_digests: :environment do
      Decidim::Authorization.all.each do |authorization|
        next if authorization.name != "gbglogin_eid" || authorization.pseudonymized_pin.present?

        authorization.update(
          pseudonymized_pin: authorization.metadata["pin_digest"]
        )
      end
    end
  end
end
