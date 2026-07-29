RSpec.describe "Api::V1::Bookmakers", type: :request do
  let!(:user) { create(:user) }
  let(:headers) { authenticated_headers(user) }
  describe "DELETE /api/v1/bookmakers/:id" do
    context "when the bookmaker exists" do
      let!(:bookmaker) { create(:bookmaker, user: create(:user)) }

      it "deletes the bookmaker" do
        expect {
          delete "/api/v1/bookmakers/#{bookmaker.id}", headers: headers
        }.to change(Bookmaker, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context "when the bookmaker has active accounts" do
      let!(:bookmaker) { create(:bookmaker, user: create(:user)) }
      let!(:account) { create(:account, bookmaker: bookmaker) }

      it "returns an error" do
        delete "/api/v1/bookmakers/#{bookmaker.id}", headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(error_response["code"])
          .to eq("not_found")
        expect(error_response["message"])
          .to eq("Resource not found.")
      end
    end

    context "when the bookmaker does not exist" do
      let!(:bookmaker_id) { Bookmaker.maximum(:id).to_i + 1  }

      it "returns a not found error" do
        delete "/api/v1/bookmakers/#{bookmaker_id}", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(error_response["code"])
          .to eq("not_found")
        expect(error_response["message"])
          .to eq("Resource not found.")
      end
    end
  end

  def error_response
    response.parsed_body.fetch("error")
  end
end

