module Shield::LoginCredentials
  macro included
    include Shield::BearerCredentials

    def initialize(@password : String, @id : {{ Login::PRIMARY_KEY_TYPE }})
    end

    def self.new(operation : Shield::StartLogin, record : Shield::Login)
      new(operation.token, record.id)
    end

    def login : Login
      login?.not_nil!
    end

    getter? login : Login? do
      LoginQuery.new.id(id).first?
    end
  end
end
