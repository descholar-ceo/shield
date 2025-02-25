module Shield::Api::SkipAuthenticationCache
  macro included
    include Shield::SkipAuthenticationCache

    def current_login? : Login?
      LoginHeaders.new(context.request).verify
    end

    {% if Avram::Model.all_subclasses
      .map(&.stringify)
      .includes?("BearerLogin") %}

      def current_bearer? : User?
        current_bearer_login?.try &.user
      end

      def current_bearer_login? : BearerLogin?
        BearerLoginHeaders.new(context.request).verify
      end
    {% end %}
  end
end
