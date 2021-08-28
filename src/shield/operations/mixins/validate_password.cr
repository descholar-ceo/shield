module Shield::ValidatePassword
  # References:
  #
  # - https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
  macro included
    before_save do
      require_lowercase
      require_uppercase
      require_number
      require_special_char
      validate_password_length
    end

    private def require_lowercase
      return unless Shield.settings.password_require_lowercase

      password.value.try do |value|
        value.each_char { |char| return if char.ascii_lowercase? }
        password.add_error("must contain a lowercase letter")
      end
    end

    private def require_uppercase
      return unless Shield.settings.password_require_uppercase

      password.value.try do |value|
        value.each_char { |char| return if char.ascii_uppercase? }
        password.add_error("must contain an uppercase letter")
      end
    end

    private def require_number
      return unless Shield.settings.password_require_number

      password.value.try do |value|
        value.each_char { |char| return if char.ascii_number? }
        password.add_error("must contain a number")
      end
    end

    private def require_special_char
      return unless Shield.settings.password_require_special_char

      password.value.try do |value|
        value.each_char { |char| return unless char.ascii_alphanumeric? }
        password.add_error("must contain a special character")
      end
    end

    private def validate_password_length
      validate_size_of password,
        min: Shield.settings.password_min_length,
        max: 64, # To mitigate DoS. Also cuz bcrypt has a max length
        allow_nil: true
    end
  end
end
