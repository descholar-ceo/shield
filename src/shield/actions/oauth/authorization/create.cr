module Shield::Oauth::Authorization::Create
  macro included
    include Shield::Oauth::Authorization::Pipes

    before :oauth_validate_client_id
    # before :oauth_handle_errors
    before :oauth_check_duplicate_params
    before :oauth_require_authorization_params
    before :oauth_validate_response_type
    before :oauth_validate_redirect_uri
    before :oauth_validate_scope
    before :oauth_require_code_challenge
    before :oauth_validate_code_challenge_method
    before :oauth_require_logged_in

    # post "/oauth/authorization" do
    #   run_operation
    # end

    def run_operation
      StartOauthGrant.create(
        params,
        scopes: scopes,
        type: OauthGrantType.new(OauthGrantType::AUTHORIZATION_CODE),
        oauth_client: oauth_client?,
        user: user
      ) do |operation, oauth_grant|
        if operation.saved?
          do_run_operation_succeeded(operation, oauth_grant.not_nil!)
        else
          response.status_code = 400
          do_run_operation_failed(operation)
        end
      end
    end

    def do_run_operation_succeeded(operation, oauth_grant)
      code = OauthGrantCredentials.new(operation, oauth_grant)
      redirect to: oauth_redirect_uri(code: code.to_s, state: state).to_s
    end

    def do_run_operation_failed(operation)
      error = operation.granted.value ? "invalid_request" : "access_denied"
      redirect to: oauth_redirect_uri(error: error, state: state).to_s
    end

    def user
      current_user
    end

    def client_id : String?
      nested_param?(:oauth_client_id)
    end

    def code_challenge : String?
      nested_param?(:code_challenge)
    end

    def code_challenge_method : String
      nested_param?(:code_challenge_method) || OauthGrantPkce::METHOD_PLAIN
    end

    def redirect_uri : String?
      nested_param?(:redirect_uri)
    end

    def response_type : String?
      nested_param?(:response_type)
    end

    def scopes : Array(String)
      nested_array_param(:scopes)
    end

    def state : String?
      nested_param?(:state)
    end

    def scope : String
      scopes.join(' ')
    end

    private def nested_param?(param)
      params.nested?(StartOauthGrant.param_key)[param.to_s]?
    end

    private def nested_array_param(param)
      params.nested_arrays?(StartOauthGrant.param_key)[param.to_s]? ||
        Array(String).new
    end
  end
end
