module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last

    return render_unauthorized if token.blank?

    payload = Jwt::Decoder.call(token:)

    @current_user = User.find(payload["user_id"])
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
