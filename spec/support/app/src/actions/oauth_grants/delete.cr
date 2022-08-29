class OauthGrants::Delete < BrowserAction
  include Shield::OauthGrants::Delete

  skip :pin_login_to_ip_address

  delete "/oauth/grants/:oauth_grant_id/delete" do
    run_operation
  end

  def do_run_operation_succeeded(operation, oauth_grant)
    response.headers["X-OAuth-Grant-ID"] = oauth_grant.id.to_s
    previous_def
  end
end
