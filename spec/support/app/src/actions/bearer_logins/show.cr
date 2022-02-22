class BearerLogins::Show < BrowserAction
  include Shield::BearerLogins::Show

  skip :check_authorization
  skip :pin_login_to_ip_address

  get "/bearer_logins/:bearer_login_id" do
    html ShowPage, bearer_login: bearer_login, token: token
  end
end
