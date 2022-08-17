require "../../../../../spec_helper"

describe Shield::Api::CurrentUser::OauthAccessTokens::Delete do
  it "deletes OAuth access tokens" do
    email = "user@example.tld"
    password = "password4APASSWORD<"

    client = ApiClient.new
    client.api_auth(email, password)

    response = client.exec(Api::CurrentUser::OauthAccessTokens::Delete)

    response.should send_json(200, {
      message: "action.current_user.bearer_login.destroy.success"
    })
  end

  it "requires logged in" do
    response = ApiClient.exec(Api::CurrentUser::OauthAccessTokens::Delete)

    response.should send_json(401, logged_in: false)
  end
end
