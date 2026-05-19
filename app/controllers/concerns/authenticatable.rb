module Authenticatable
  extend ActiveSupport::Concern

  included { before_action :authenticate_user! }

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last

    return render_unauthorized if token.blank?

    payload = Jwt::Decoder.call(token: token)

    @current_user = User.find(payload["user_id"])
  end

  def current_user
    @current_user
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
