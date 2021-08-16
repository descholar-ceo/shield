module Shield::EmailConfirmationHelpers
  macro included
    def redirect(to path : Shield::EmailConfirmationUrl, status : Int32 = 302)
      redirect(path.to_s, status)
    end
  end
end
