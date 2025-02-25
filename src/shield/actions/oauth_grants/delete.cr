module Shield::OauthGrants::Delete
  macro included
    include Shield::OauthGrants::Destroy

    # delete "/oauth/grants/:oauth_grant_id" do
    #   run_operation
    # end

    def run_operation
      DeleteOauthGrant.delete(oauth_grant) do |operation, deleted_oauth_grant|
        if operation.deleted?
          do_run_operation_succeeded(operation, deleted_oauth_grant.not_nil!)
        else
          response.status_code = 400
          do_run_operation_failed(operation)
        end
      end
    end
  end
end
