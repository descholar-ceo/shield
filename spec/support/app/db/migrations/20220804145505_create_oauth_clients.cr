class CreateOauthClients::V20220804145505 < Avram::Migrator::Migration::V1
  def migrate
    enable_extension "pgcrypto"

    create :oauth_clients do
      primary_key id : UUID

      add_belongs_to user : User, on_delete: :cascade

      add active_at : Time
      add inactive_at : Time?
      add name : String
      add redirect_uri : String
      add secret_digest : String?
    end
  end

  def rollback
    drop :oauth_clients
  end
end
