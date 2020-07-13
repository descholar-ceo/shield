module Shield::CreatePasswordReset
  macro included
    skip :require_authorization
    skip :require_logged_in

    before :require_logged_out

    # post "/password-resets" do
    #   save_password_reset
    # end

    private def save_password_reset
      StartPasswordReset.create(
        params,
        ip_address: remote_ip
      ) do |operation, password_reset|
        if password_reset
          success_action(operation, password_reset.not_nil!)
        else
          failure_action(operation)
        end
      end
    end

    private def success_action(operation, password_reset)
      success_action
    end

    private def failure_action(operation)
      if operation.guest_email?
        success_action
      else
        flash.failure = "Password reset request failed"
        html NewPage, operation: operation
      end
    end

    private def success_action
      flash.success = "Done! Check your email for further instructions."
      redirect to: Logins::New
    end
  end
end
