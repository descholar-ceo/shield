module Shield::EmailConfirmationCurrentUser::Create
  # IMPORTANT!
  #
  # Prevent user enumeration by showing the same response
  # even if the email address is already registered.
  #
  # This assumes we're sending welcome emails.
  macro included
    include Shield::CurrentUser::Create

    before :pin_email_confirmation_to_ip_address

    # post "/account" do
    #   run_operation
    # end

    def run_operation
      EmailConfirmationSession.new(
        session
      ).verify do |utility, email_confirmation|
        if email_confirmation
          register_user(email_confirmation.not_nil!)
        else
          response.status_code = 403
          do_verify_operation_failed(utility)
        end
      end
    end

    private def register_user(email_confirmation)
      RegisterCurrentUser.create(
        params,
        email_confirmation: email_confirmation,
        session: session,
      ) do |operation, user|
        if user
          do_run_operation_succeeded(operation, user.not_nil!)
        else
          do_run_operation_failed(operation)
        end
      end
    end

    def do_verify_operation_failed(utility)
      flash.keep.failure = "Invalid token"
      redirect to: EmailConfirmations::New
    end

    def do_run_operation_failed(operation)
      if operation.user_email?
        success_action(operation) # <= IMPORTANT!
      else
        flash.failure = "Could not create your account"

        html NewPage,
          operation: operation,
          email_confirmation: operation.email_confirmation
      end
    end
  end
end
