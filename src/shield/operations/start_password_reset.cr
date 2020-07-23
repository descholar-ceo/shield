module Shield::StartPasswordReset
  macro included
    getter? guest_email = false

    attribute user_email : String

    before_save do
      downcase_user_email

      validate_user_email
      validate_required user_email

      set_user_id
      set_guest_email

      send_guest_email
    end

    after_commit send_email

    include Shield::StartAuthentication(PasswordReset)

    private def downcase_user_email
      user_email.value.try { |value| user_email.value = value.downcase }
    end

    private def validate_user_email
      user_email.value.try do |value|
        user_email.add_error("format invalid") unless value.email?
      end
    end

    private def set_user_id
      user_email.value.try do |value|
        user_id.value = User.from_email(value).try(&.id)
      end
    end

    private def set_guest_email
      @guest_email = user_id.value.nil? && user_email.valid?
    end

    private def send_guest_email
      return unless guest_email?
      mail_later GuestPasswordResetRequestEmail, self
    end

    private def send_email(password_reset : PasswordReset)
      mail_later PasswordResetRequestEmail, self, password_reset
    end
  end
end
