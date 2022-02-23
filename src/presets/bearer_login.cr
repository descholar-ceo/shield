{% skip_file unless Avram::Model.all_subclasses
  .map(&.stringify)
  .includes?("BearerLogin")
%}

require "../compat/bearer_login"

class User < BaseModel
  include Shield::HasManyBearerLogins
end

class BearerLoginQuery < BearerLogin::BaseQuery
  include Shield::BearerLoginQuery
end

class CreateCurrentUserBearerLogin < BearerLogin::SaveOperation
  include Shield::CreateBearerLogin
end

class RevokeBearerLogin < BearerLogin::SaveOperation
  include Shield::RevokeBearerLogin
end

class DeleteBearerLogin < BearerLogin::DeleteOperation
  include Shield::DeleteBearerLogin
end

class RevokeCurrentUserBearerLogins < User::SaveOperation
  include Shield::RevokeUserBearerLogins
end

class DeleteCurrentUserBearerLogins < User::SaveOperation
  include Shield::DeleteUserBearerLogins
end

abstract class ApiAction < Lucky::Action
  include Shield::Api::BearerLoginHelpers
  include Shield::Api::BearerLoginPipes
end

struct BearerLoginHeaders
  include Shield::BearerLoginHeaders
end

struct BearerTokenSession
  include Shield::BearerTokenSession
end
