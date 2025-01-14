require "../../../../spec_helper"

describe Shield::EmailConfirmations::Token::Show do
  it "sets session" do
    StartEmailConfirmation.create(
      params(email: "email@domain.tld"),
      remote_ip: Socket::IPAddress.new("1.2.3.4", 5)
    ) do |operation, email_confirmation|
      email_confirmation = email_confirmation.not_nil!

      response = ApiClient.get(EmailConfirmationUrl.new(
        operation,
        email_confirmation
      ).to_s)

      response.status.should eq(HTTP::Status::FOUND)

      session = ApiClient.session_from_cookies(response.cookies)

      from_session = EmailConfirmationSession.new(session)

      from_session.email_confirmation_id?.should(eq email_confirmation.id)
      from_session.email_confirmation_token?.should eq(operation.token)
    end
  end
end
