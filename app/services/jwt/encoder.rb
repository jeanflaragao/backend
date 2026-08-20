module Jwt
  class Encoder
    SECRET_KEY =
      Rails.application.credentials.secret_key_base ||
      Rails.application.secret_key_base

    def self.call(payload:)
      JWT.encode(
        payload,
        SECRET_KEY,
        "HS256"
      )
    end
  end
end
