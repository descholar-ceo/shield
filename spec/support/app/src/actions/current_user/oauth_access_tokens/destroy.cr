class CurrentUser::OauthAccessTokens::Destroy < BrowserAction
  include Shield::CurrentUser::OauthAccessTokens::Destroy

  skip :pin_login_to_ip_address

  delete "/account/oauth/tokens" do
    run_operation
  end

  def do_run_operation_succeeded(operation, user)
    response.headers["X-User-ID"] = user.id.to_s
    previous_def
  end
end
