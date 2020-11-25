module Shield::DeleteSession
  macro included
    needs session : Lucky::Session? = nil

    after_commit delete_session
  end
end
