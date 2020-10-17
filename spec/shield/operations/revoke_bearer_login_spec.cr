require "../../spec_helper"

describe Shield::RevokeBearerLogin do
  it "ends bearer login" do
    session = Lucky::Session.new

    bearer_login = CreateBearerLogin.create!(
      params(name: "some token"),
      user_id: UserBox.create.id,
      scopes: ["posts.index"],
      all_scopes: ["posts.index", "posts.create"]
    )

    RevokeBearerLogin.update(
      bearer_login,
      params(status: "Expired"),
      status: BearerLogin::Status.new(:started)
    ) do |operation, updated_bearer_login|
      operation.saved?.should be_true

      updated_bearer_login.ended_at.should be_a(Time)
      updated_bearer_login.status.ended?.should be_true
    end
  end
end