module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ApplicationError, with: :render_business_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  end

  private

  def render_business_error(exception)
    render json: {
      error: {
        code: exception.code,
        message: exception.message
      }
    }, status: :unprocessable_entity
  end

  def render_not_found(_exception)
    render json: {
      error: {
        code: "resource_not_found",
        message: "Resource not found."
      }
    }, status: :not_found
  end
end