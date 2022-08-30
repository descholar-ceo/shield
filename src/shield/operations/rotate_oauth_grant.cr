module Shield::RotateOauthGrant
  macro included
    needs oauth_grant : OauthGrant

    include Lucille::Activate
    include Shield::SetOauthGrantCode

    before_save do
      set_oauth_client_id
      set_user_id
      set_scopes
      set_type
      set_inactive_at
      set_success
    end

    after_save end_oauth_grant

    include Shield::ValidateOauthGrant

    private def validate_user_exists
    end

    private def validate_oauth_client_exists
    end

    private def set_oauth_client_id
      return unless oauth_grant.status.active?
      oauth_client_id.value = oauth_grant.oauth_client_id
    end

    private def set_user_id
      return unless oauth_grant.status.active?
      user_id.value = oauth_grant.user_id
    end

    private def set_scopes
      return unless oauth_grant.status.active?
      scopes.value = oauth_grant.scopes
    end

    def set_type
      type.value = OauthGrantType.new(OauthGrantType::REFRESH_TOKEN)
    end

    private def set_inactive_at
      Shield.settings.oauth_refresh_token_expiry.try do |expiry|
        active_at.value.try { |value| inactive_at.value = value + expiry }
      end
    end

    private def set_success
      success.value = false
    end

    private def end_oauth_grant(__ : OauthGrant)
      EndOauthGrantGracefully.update!(oauth_grant, success: true)
    end
  end
end