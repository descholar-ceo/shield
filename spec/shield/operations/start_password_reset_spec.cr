require "../../spec_helper"

describe Shield::StartPasswordReset do
  it "saves password reset" do
    email = "user@example.tld"

    user = UserFactory.create &.email(email)
    ip_address = Socket::IPAddress.new("129.0.0.5", 5555)

    StartPasswordReset.create(
      params(email: email),
      remote_ip: ip_address
    ) do |operation, password_reset|
      password_reset.should be_a(PasswordReset)
      operation.token.should_not be_empty

      password_reset.try do |password_reset|
        password_reset.status.active?.should be_true
        password_reset.inactive_at.should_not be_nil
        password_reset.ip_address.should(eq ip_address.address)
        password_reset.token_digest.should_not(be_empty)
        password_reset.user_id.should(eq user.id)
      end
    end
  end

  it "requires email" do
    StartPasswordReset.create(remote_ip: nil) do |operation, password_reset|
      password_reset.should be_nil
      assert_invalid(operation.email, "operation.error.email_required")
    end
  end

  it "requires existing email" do
    StartPasswordReset.create(
      params(email: "user@example.tld"),
      remote_ip: nil
    ) do |operation, password_reset|
      password_reset.should be_nil
      operation.guest_email?.should be_true

      assert_valid(operation.user_id)
      assert_invalid(operation.email, "operation.error.email_not_found")
    end
  end

  it "requires valid IP address" do
    StartPasswordReset.create(
      params(email: "user@example.tld"),
      remote_ip: nil
    ) do |operation, password_reset|
      password_reset.should be_nil

      assert_invalid(
        operation.ip_address,
        "operation.error.ip_address_required"
      )
    end
  end

  it "rejects invalid email" do
    StartPasswordReset.create(
      params(email: "email"),
      remote_ip: Socket::IPAddress.new("0.0.0.0", 0)
    ) do |operation, password_reset|
      password_reset.should be_nil
      operation.guest_email?.should be_false

      assert_invalid(operation.email, "operation.error.email_invalid")
    end
  end

  it "sends guest email" do
    StartPasswordReset.create(
      params(email: "user@example.tld"),
      remote_ip: Socket::IPAddress.new("0.0.0.0", 0)
    ) do |operation, password_reset|
      password_reset.should be_nil
      GuestPasswordResetRequestEmail.new(operation).should be_delivered
    end
  end

  it "sends password reset request email" do
    email = "user@example.tld"

    UserFactory.create &.email(email)

    StartPasswordReset.create(
      params(email: email),
      remote_ip: Socket::IPAddress.new("0.0.0.0", 0)
    ) do |operation, password_reset|
      GuestPasswordResetRequestEmail.new(operation).should_not be_delivered

      password_reset = PasswordResetQuery.preload_user(password_reset.not_nil!)

      PasswordResetRequestEmail.new(operation, password_reset)
        .should(be_delivered)
    end
  end
end
