module Shield::NotifyPasswordChange
  macro included
    after_commit notify_password_change

    private def notify_password_change(user : Shield::User)
      return unless password_digest.changed?

      user = UserQuery.preload_options(user)
      return unless user.options.password_notify

      mail_later PasswordChangeNotificationEmail, self, user
    end
  end
end
