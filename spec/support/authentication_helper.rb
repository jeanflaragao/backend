module AuthenticationHelper
  def authenticated_headers(user)
    token = Jwt::Encoder.call(
      payload: {
        user_id: user.id
      }
    )

    {
      "Authorization" => "Bearer #{token}"
    }
  end
end
