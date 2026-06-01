module Api
  module V1
    class BookmakersController < ApplicationController
      include Authenticatable

      def index
        relation =
          Bookmakers::IndexQuery.call(
            relation: policy_scope(Bookmaker),
            params: params
          )

        @pagy, bookmakers = pagy(relation)

        serialized_data = BookmakerSerializer.new(bookmakers).serializable_hash

        render json: {
                 data: serialized_data,
                 meta: pagy_metadata(@pagy)
               },
               status: :ok
      end

      def show
        bookmaker = Bookmaker.find(params[:id])

        authorize bookmaker

        render json: BookmakerSerializer.new(bookmaker).serialize, status: :ok
      end

      def create
        result =
          Bookmakers::CreateService.call(
            user: current_user,
            params: bookmaker_params
          )

        if result[:success]
          render json: BookmakerSerializer.new(result[:bookmaker]).serialize,
                 status: :created
        else
          render json: {
                   errors: result[:errors]
                 },
                 status: :unprocessable_entity
        end
      end

      private

      def filter_params
        params.permit(:status, :country)
      end

      def bookmaker_params
        params.require(:bookmaker).permit(:name, :website, :country, :status)
      end
    end
  end
end
