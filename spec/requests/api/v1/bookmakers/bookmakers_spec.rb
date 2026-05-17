require "rails_helper"

RSpec.describe "Api::V1::Bookmakers", type: :request do
  let!(:user) { create(:user) }
  let(:headers) { authenticated_headers(user) }

  describe "GET /api/v1/bookmakers" do
    before do
      create_list(:bookmaker, 3, user: user)
    end

    context "when authenticated" do
      it "returns all bookmakers" do
        get "/api/v1/bookmakers", headers: headers

        expect(response).to have_http_status(:ok)
      end
    end

    context "when unauthenticated" do
      it "returns unauthorized" do
        get "/api/v1/bookmakers"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/bookmakers/:id" do
    let(:bookmaker) { create(:bookmaker, user: user) }

    it "returns the bookmaker" do
      get "/api/v1/bookmakers/#{bookmaker.id}", headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["id"]).to eq(bookmaker.id)
      expect(body["name"]).to eq(bookmaker.name)
    end

    it "returns not found for invalid id" do
      get "/api/v1/bookmakers/999999", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns serialized bookmaker data" do
      bookmaker = create(:bookmaker, user: user)

      get "/api/v1/bookmakers/#{bookmaker.id}", headers: headers

      json = response.parsed_body

      expect(json.keys).to contain_exactly(
        "id",
        "name",
        "homepage",
        "country",
        "status"
      )
    end
  end

  describe "POST /api/v1/bookmakers" do
    let(:valid_params) do
      {
        bookmaker: {
          name: "Betano POST",
          website: "https://betano.com",
          country: "Brazil",
          status: "active"
        }
      }
    end

    it "creates a bookmaker" do
      expect {
        post "/api/v1/bookmakers", params: valid_params, headers: headers
      }.to change(Bookmaker, :count).by(1)

      expect(response).to have_http_status(:created)

      body = response.parsed_body

      expect(body["name"]).to eq("Betano POST")
    end

    it "returns errors for duplicate bookmaker name" do
      post "/api/v1/bookmakers", params: valid_params, headers: headers

      expect(response).to have_http_status(:created)

      post "/api/v1/bookmakers", params: valid_params, headers: headers

      expect(response).to have_http_status(:unprocessable_content)

      body = response.parsed_body

      expect(body["errors"]).to include("Name has already been taken")
    end

    it "returns validation errors" do
      invalid_params = {
        bookmaker: {
          name: nil
        }
      }

      post "/api/v1/bookmakers", params: invalid_params, headers: headers

      expect(response).to have_http_status(:unprocessable_content)

      body = response.parsed_body

      expect(body["errors"]).to include("Name can't be blank")
    end
  end

  describe "FILTER /api/v1/bookmakers" do
    let(:params) { {} }

    subject(:make_request) do
      get "/api/v1/bookmakers",
          params: params,
          headers: headers
    end

    let!(:betano) do
      create(
        :bookmaker,
        user: user,
        name: "Betano FILTER",
        status: "active",
        country: "Brazil"
      )
    end

    let!(:stake) do
      create(
        :bookmaker,
        user: user,
        name: "Stake",
        status: "inactive",
        country: "Brazil"
      )
    end

    let!(:bet365) do
      create(
        :bookmaker,
        user: user,
        name: "Bet365",
        status: "active",
        country: "United Kingdom"
      )
    end

    context "when filtering by status" do
      let(:params) do
        {
          status: "active"
        }
      end

      it "returns only active bookmakers" do
        get "/api/v1/bookmakers",
          headers: headers,
          params: params

        body = response.parsed_body

        names = body["data"].map do |bookmaker|
          bookmaker["name"]
        end

        expect(names).to contain_exactly(
          "Betano FILTER",
          "Bet365"
        )
      end
    end

    context "when filtering by country" do
      let(:params) do
        {
          country: "Brazil"
        }
      end

      it "returns only Brazilian bookmakers" do
        make_request

        body = response.parsed_body

        names = body["data"].map do |bookmaker|
          bookmaker["name"]
        end

        expect(names).to contain_exactly(
          "Betano FILTER",
          "Stake"
        )
      end
    end

    context "when filtering by search" do
      let(:params) do
        {
          search: "bet"
        }
      end

      it "returns matching bookmakers" do
        make_request

        body = response.parsed_body

        names = body["data"].map do |bookmaker|
          bookmaker["name"]
        end

        expect(names).to contain_exactly(
          "Betano FILTER",
          "Bet365"
        )
      end
    end
  end
end
