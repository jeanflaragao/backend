module Api
  module V1
    class BookmakersController < ApplicationController
      def index
        bookmakers = Bookmaker.all

        render json: bookmakers, status: :ok
      end

      def show
        bookmaker = Bookmaker.find(params[:id])

        render json: bookmaker, status: :ok
      end

      def create
        result = Bookmakers::CreateService.call(
          params: bookmaker_params
        )

        if result[:success]
          render json: result[:bookmaker], status: :created
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