module Shield::NotifyLoginIfSet
  macro included
    after_commit notify_login

    private def notify_login(login : Shield::Login)
      login = LoginQuery.preload_user(login)
      return unless login.user.settings.login_notify?

      mail_later LoginNotificationEmail, self, login
    end
  end
end
