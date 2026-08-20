require "rails_helper"

RSpec.describe "Api::V1::Bookmakers", type: :request do
  let(:user) { create(:user) }
  let(:headers) { authenticated_headers(user) }

  describe "DELETE /api/v1/bookmakers/:id" do
    context "when the bookmaker belongs to the authenticated user" do
      let!(:bookmaker) { create(:bookmaker, user: user) }

      it "returns no content, an empty body, and deletes the bookmaker" do
        expect {
          delete "/api/v1/bookmakers/#{bookmaker.id}", headers: headers
        }.to change(Bookmaker, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
        expect(Bookmaker.exists?(bookmaker.id)).to be(false)
      end
    end

    context "when the bookmaker belongs to another user" do
      let(:other_user) { create(:user) }
      let!(:bookmaker) { create(:bookmaker, user: other_user) }

      it "returns not found, exposes resource_not_found, and keeps the bookmaker" do
        expect {
          delete "/api/v1/bookmakers/#{bookmaker.id}", headers: headers
        }.not_to change(Bookmaker, :count)

        expect(response).to have_http_status(:not_found)
        expect(error_response).to eq(
          "code" => "resource_not_found",
          "message" => "Resource not found."
        )
        expect(Bookmaker.exists?(bookmaker.id)).to be(true)
      end
    end

    context "when the bookmaker does not exist" do
      let(:bookmaker_id) { Bookmaker.maximum(:id).to_i + 1 }

      it "returns a not found error" do
        expect {
          delete "/api/v1/bookmakers/#{bookmaker_id}", headers: headers
        }.not_to change(Bookmaker, :count)

        expect(response).to have_http_status(:not_found)
        expect(error_response).to eq(
          "code" => "resource_not_found",
          "message" => "Resource not found."
        )
      end
    end

    context "when unauthenticated" do
      let!(:bookmaker) { create(:bookmaker, user: user) }

      it "returns unauthorized and keeps the bookmaker" do
        expect {
          delete "/api/v1/bookmakers/#{bookmaker.id}"
        }.not_to change(Bookmaker, :count)

        expect(response).to have_http_status(:unauthorized)
        expect(Bookmaker.exists?(bookmaker.id)).to be(true)
      end
    end
  end

  def error_response
    response.parsed_body.fetch("error")
  end
end

