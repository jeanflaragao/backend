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
        bookmaker = Bookmaker.new(bookmaker_params)

        if bookmaker.save
          render json: bookmaker, status: :created
        else
          render json: {
            errors: bookmaker.errors.full_messages
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