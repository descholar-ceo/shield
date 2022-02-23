require "../../../../spec_helper"

describe Shield::CurrentUser::BearerLogins::Delete do
  it "deletes bearer logins" do
    email = "user@example.tld"
    password = "password4APASSWORD<"

    client = ApiClient.new
    client.browser_auth(email, password)

    response = client.exec(CurrentUser::BearerLogins::Delete)

    response.status.should eq(HTTP::Status::FOUND)
    response.headers["X-User-ID"]?.should_not be_nil
  end

  it "requires logged in" do
    response = ApiClient.exec(CurrentUser::BearerLogins::Delete)

    response.status.should eq(HTTP::Status::FOUND)
    response.headers["X-Logged-In"]?.should eq("false")
  end
end
