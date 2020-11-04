abstract class BrowserAction < Lucky::Action
  include Shield::BrowserAction

  accepted_formats [:json]

  skip :protect_from_forgery

  def do_require_logged_in_failed
    response.headers["X-Logged-In"] = "false"
    response.headers["X-Return-Url"] = ReturnUrlSession.new(session)
      .return_url
      .to_s

    previous_def
  end

  def do_require_logged_out_failed
    response.headers["X-Logged-In"] = "true"
    previous_def
  end

  def do_check_authorization_failed
    response.headers["X-Authorized"] = "false"
    previous_def
  end

  def do_pin_login_to_ip_address_failed
    response.headers["X-IP-Address-Changed"] = "true"
    previous_def
  end

  def do_pin_password_reset_to_ip_address_failed
    response.headers["X-Ip-Address-Changed"] = "true"
    previous_def
  end

  def do_pin_email_confirmation_to_ip_address_failed
    response.headers["X-Ip-Address-Changed"] = "true"
    previous_def
  end

  def authorize?(user : User) : Bool
    user.level.admin?
  end
end
