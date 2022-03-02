class CurrentUser::PasswordResets::Delete < BrowserAction
  include Shield::CurrentUser::PasswordResets::Delete

  delete "/account/password-resets/delete" do
    run_operation
  end

  def do_run_operation_succeeded(operation, password_reset)
    response.headers["X-End-Password-Resets"] = "true"
    previous_def
  end

  def remote_ip? : Socket::IPAddress?
    Socket::IPAddress.new("128.0.0.2", 5000)
  end
end
