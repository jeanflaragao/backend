module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    header = request.headers["Authorization"]

    token = header.split(" ").last if header.present?

    decoded = Jwt::Decoder.call(token: token)

    @current_user = User.find_by(id: decoded["user_id"]) if decoded

    render_unauthorized unless @current_user
  end

  def current_user
    @current_user
  end

  def render_unauthorized
    render json: {
      error: "Unauthorized"
    }, status: :unauthorized
  end
end
