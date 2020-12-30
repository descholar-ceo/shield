require "../../../spec_helper"

describe Shield::PasswordResets::Show do
  it "sets session" do
    email = "user@example.tld"
    password = "password4APASSWORD<"

    UserBox.create &.email(email)
      .password_digest(CryptoHelper.hash_bcrypt(password))

    StartPasswordReset.create(
      params(email: email),
      remote_ip: Socket::IPAddress.new("0.0.0.0", 0)
    ) do |operation, password_reset|
      password_reset = password_reset.not_nil!

      response = ApiClient.get(PasswordResetUrl.new(
        operation,
        password_reset
      ).to_s)

      response.status.should eq(HTTP::Status::FOUND)

      cookies = Lucky::CookieJar.from_request_cookies(response.cookies)
      session = Lucky::Session.from_cookie_jar(cookies)

      PasswordResetSession
        .new(session)
        .password_reset_id
        .should eq(password_reset.id)

      PasswordResetSession
        .new(session)
        .password_reset_token
        .should eq(operation.token)
    end
  end

  it "requires logged out" do
    email = "user@example.tld"
    password = "password4APASSWORD<"

    client = ApiClient.new
    client.browser_auth(email, password)

    response = client.get(PasswordResetUrl.new("abcdef", 1_i64).to_s)

    response.status.should eq(HTTP::Status::FOUND)
    response.headers["X-Logged-In"].should eq("true")
  end
end
