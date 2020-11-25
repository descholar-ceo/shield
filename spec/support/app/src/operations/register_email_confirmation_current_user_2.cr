require "./save_user_options_2"

class RegisterEmailConfirmationCurrentUser2 < User::SaveOperation
  attribute password : String

  has_one_create save_user_options : SaveUserOptions2, assoc_name: :options

  before_save set_level

  include Shield::SetEmailFromEmailConfirmation
  include Shield::SaveEmail
  include Shield::CreatePassword
  include Shield::DeleteSession

  private def set_level
    level.value = User::Level.new(:author)
  end

  private def delete_session(user : User)
    session.try { |session| EmailConfirmationSession.new(session).delete }
  end
end
