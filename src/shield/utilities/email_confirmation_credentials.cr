module Shield::EmailConfirmationCredentials
  macro included
    include Shield::ParamCredentials

    def initialize(
      @password : String,
      @id : EmailConfirmation::PrimaryKeyType
    )
    end

    def self.new(
      operation : EmailConfirmation::SaveOperation,
      email_confirmation : Shield::EmailConfirmation
    )
      new(operation.token, email_confirmation.id)
    end

    def email_confirmation : EmailConfirmation
      email_confirmation?.not_nil!
    end

    getter? email_confirmation : EmailConfirmation? do
      EmailConfirmationQuery.new.id(id).preload_user.first?
    end

    def url : String
      Shield.settings.email_confirmation_url.call(to_s)
    end
  end
end
