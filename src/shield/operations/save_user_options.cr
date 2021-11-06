module Shield::SaveUserOptions
  macro included
    permit_columns :password_notify

    before_save do
      validate_user_id_required
      validate_password_notify_required
      validate_user_exists
    end

    private def validate_password_notify_required
      validate_required password_notify
    end

    private def validate_user_id_required
      validate_required user_id
    end

    private def validate_user_exists
      return unless user_id.changed?
      validate_foreign_key(user_id, query: UserQuery)
    end
  end
end
