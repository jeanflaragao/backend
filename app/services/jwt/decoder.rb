module Jwt
  class Decoder
    SECRET_KEY = Rails.application.credentials.secret_key_base

    def self.call(token:)
      decoded_token = JWT.decode(
          token,
          SECRET_KEY,
          true,
          { algorithm: "HS256" }
        )
      decoded_token.first
    end
  rescue JWT::DecodeError
    nil
  end
end
