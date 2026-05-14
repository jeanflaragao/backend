module Api
  module V1
    class BookmakersController < ApplicationController
      include Authenticatable

      def index
        bookmakers = policy_scope(Bookmaker)

        render json: BookmakerSerializer.new(bookmakers).serialize, status: :ok
      end

      def show
        bookmaker = Bookmaker.find(params[:id])

        authorize bookmaker

        render json: BookmakerSerializer.new(bookmaker).serialize, status: :ok
      end

      def create
        result = Bookmakers::CreateService.call(
          user: current_user,
          params: bookmaker_params
        )

        if result[:success]
          render json: BookmakerSerializer.new(result[:bookmaker]).serialize,
          status: :created
        else
          render json: {
            errors: result[:errors]
          }, status: :unprocessable_entity
        end
      end

      private

      def bookmaker_params
        params.require(:bookmaker).permit(
          :name,
          :website,
          :country,
          :status
        )
      end
    end
  end
end
