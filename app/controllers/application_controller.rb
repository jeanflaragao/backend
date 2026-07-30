class ApplicationController < ActionController::API
  include Pundit::Authorization
  include Pagy::Backend
  include ErrorHandler

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from Pagy::OverflowError, with: :render_not_found

  private

  def render_forbidden
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
