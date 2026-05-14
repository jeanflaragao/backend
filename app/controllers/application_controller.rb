class ApplicationController < ActionController::API
  include Pundit::Authorization

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def render_not_found
    render json: {
      error: "Not found"
    }, status: :not_found
  end

  def render_forbidden
    render json: {
      error: "Forbidden"
    }, status: :forbidden
  end
end
