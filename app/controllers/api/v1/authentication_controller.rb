module Api
  module V1
    class AuthenticationController < ApplicationController
      def create
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          token = Jwt::Encoder.call(
            payload: {
              user_id: user.id
            }
          )

          render json: { token: token }, status: :ok
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end
    end
  end
end
