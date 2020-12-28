module Shield::UpdateConfirmedEmail
  macro included
    after_save end_email_confirmations

    after_completed do |saved_record|
      end_email_confirmations(saved_record) if changes.empty?
    end

    include Shield::SetEmailFromEmailConfirmation
    include Shield::SaveEmail
    include Shield::DeleteSession

    private def end_email_confirmations(user : User)
      EmailConfirmationQuery.new
        .email(user.email)
        .is_active
        .update(ended_at: Time.utc)
    end

    private def delete_session(user : User)
      session.try { |session| EmailConfirmationSession.new(session).delete }
    end
  end
end
