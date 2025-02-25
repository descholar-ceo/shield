module Shield::PasswordResetCredentials
  macro included
    include Shield::ParamCredentials

    def initialize(
      @password : String,
      @id : PasswordReset::PrimaryKeyType
    )
    end

    def self.new(
      operation : PasswordReset::SaveOperation,
      password_reset : Shield::PasswordReset
    )
      new(operation.token, password_reset.id)
    end

    def password_reset : PasswordReset
      password_reset?.not_nil!
    end

    getter? password_reset : PasswordReset? do
      PasswordResetQuery.new.id(id).preload_user.first?
    end

    def url : String
      Shield.settings.password_reset_url.call(to_s)
    end
  end
end
