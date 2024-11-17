# frozen_string_literal: true

class CreateGoteborgLoginSessions < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_goteborg_login_sessions do |t|
      t.references :decidim_user, null: false, index: true
      t.string :saml_uid, limit: 1024, null: false, index: true
      t.string :saml_session_index, limit: 128, null: false
      t.datetime :ended_at
    end
  end
end
