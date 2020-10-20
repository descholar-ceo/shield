module Shield::LogUserIn
  macro included
    attribute email : String
    attribute password : String

    before_save do
      validate_required email, password
      verify_login
    end

    after_commit notify_login

    include Shield::ValidateEmail
    include Shield::RequireIpAddress
    include Shield::StartAuthentication(Login)
    include Shield::SetSession

    private def verify_login
      return unless email.value.to_s.email? && password.value

      if user = UserHelper.verify_user(
        email.value.not_nil!,
        password.value.not_nil!
      )
        user_id.value = user.not_nil!.id
      else
        email.add_error "may be incorrect"
        password.add_error "may be incorrect"
      end
    end

    private def set_session(login : Login)
      session.try do |session|
        LoginSession.new(session).set(login.id, token)
      end
    end

    private def notify_login(login : Login)
      return unless login.user!.options!.login_notify

      mail_later LoginNotificationEmail, self, login
    end
  end
end
