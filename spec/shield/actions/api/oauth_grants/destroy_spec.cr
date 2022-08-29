require "../../../../spec_helper"

describe Shield::Api::OauthGrants::Destroy do
  it "revokes OAuth grant" do
    password = "password4APASSWORD<"

    resource_owner = UserFactory.create &.email("resource@owner.com")
      .password(password)

    UserOptionsFactory.create &.user_id(resource_owner.id)

    developer = UserFactory.create
    oauth_client = OauthClientFactory.create &.user_id(developer.id)

    oauth_grant = OauthGrantFactory.create &.user_id(resource_owner.id)
      .oauth_client_id(oauth_client.id)

    client = ApiClient.new
    client.api_auth(resource_owner, password)

    response = client.exec(Api::OauthGrants::Destroy.with(
      oauth_grant_id: oauth_grant.id
    ))

    response.should send_json(200, {
      message: "action.oauth_grant.destroy.success"
    })

    oauth_grant.reload.status.inactive?.should be_true
  end

  it "requires logged in" do
    response = ApiClient.exec(Api::OauthGrants::Destroy.with(
      oauth_grant_id: 45
    ))

    response.should send_json(401, logged_in: false)
  end
end
