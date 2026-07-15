require 'rails_helper'
RSpec.describe "POST /api/v1/login", type: :request do
  let!(:user) { create(:user) }

  it "returns jwt token" do
    post "/api/v1/login",
         params: {
           email: user.email,
           password: "password123"
         }

    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)

    expect(body["token"]).to be_present
  end

  it "returns unauthorized for invalid credentials" do
    post "/api/v1/login",
        params: {
          email: user.email,
          password: "wrong-password"
        }

    expect(response).to have_http_status(:unauthorized)
  end
end
