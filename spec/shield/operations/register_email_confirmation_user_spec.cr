require "../../spec_helper"

describe Shield::RegisterEmailConfirmationUser do
  it "creates email confirmed user" do
    password = "password12U password"

    email_confirmation = StartEmailConfirmation.create!(
      params(email: "user@example.tld"),
      remote_ip: Socket::IPAddress.new("1.2.3.4", 5)
    )

    RegisterEmailConfirmationCurrentUser.create(
      params(
        password: password,
        password_confirmation: password,
        login_notify: true,
        password_notify: true
      ),
      email_confirmation: email_confirmation,
      session: Lucky::Session.new,
    ) do |operation, user|
      user.should be_a(User)

      user.try(&.email).should eq(email_confirmation.email)
      email_confirmation.reload.user_id.should eq(user.try(&.id))
    end
  end

  it "ends all active email confirmations for that email" do
    email = "user@example.tld"
    password = "password12U-password"

    email_confirmation = StartEmailConfirmation.create!(
      params(email: email),
      remote_ip: Socket::IPAddress.new("1.2.3.4", 5)
    )

    email_confirmation_2 = StartEmailConfirmation.create!(
      params(email: email),
      remote_ip: Socket::IPAddress.new("6.7.8.9", 10)
    )

    email_confirmation_3 = StartEmailConfirmation.create!(
      params(email: "abc@domain.net"),
      remote_ip: Socket::IPAddress.new("11.12.13.14", 15)
    )

    email_confirmation.status.started?.should be_true
    email_confirmation_2.status.started?.should be_true
    email_confirmation_3.status.started?.should be_true

    user = RegisterEmailConfirmationCurrentUser.create!(
      params(
        password: password,
        password_confirmation: password,
        login_notify: true,
        password_notify: true
      ),
      email_confirmation: email_confirmation,
    )

    email_confirmation.reload.status.started?.should be_false
    email_confirmation_2.reload.status.started?.should be_false
    email_confirmation_3.reload.status.started?.should be_true

    email_confirmation.reload.user_id.should eq(user.id)
    email_confirmation_2.reload.user_id.should be_nil
    email_confirmation_3.reload.user_id.should be_nil
  end

  it "creates user options" do
    password = "password12U-password"

    email_confirmation = StartEmailConfirmation.create!(
      params(email: "user@example.tld"),
      remote_ip: Socket::IPAddress.new("1.2.3.4", 5)
    )

    user = RegisterEmailConfirmationCurrentUser.create!(
      params(
        password: password,
        password_confirmation: password,
        login_notify: true,
        password_notify: false
      ),
      email_confirmation: email_confirmation,
      session: Lucky::Session.new,
    )

    user_options = user.options!

    user_options.login_notify.should be_true
    user_options.password_notify.should be_false
  end

  it "fails when nested operation fails" do
    password = "password12U password"

    email_confirmation = StartEmailConfirmation.create!(
      params(email: "user@example.tld"),
      remote_ip: Socket::IPAddress.new("1.2.3.4", 5)
    )

    RegisterEmailConfirmationCurrentUser2.create(
      params(
        password: password,
        password_confirmation: password,
        login_notify: false,
        password_notify: false
      ),
      email_confirmation: email_confirmation,
      session: Lucky::Session.new,
    ) do |operation, user|
      operation.saved?.should be_false
    end
  end
end
