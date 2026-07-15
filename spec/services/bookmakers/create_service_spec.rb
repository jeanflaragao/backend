require "rails_helper"

RSpec.describe Bookmakers::CreateService do
  describe ".call" do
    let(:user) { create(:user) }

    context "with valid params" do
      it "creates a bookmaker" do
        result = described_class.call(user: user, params: { name: "Bet365" })

        expect(result[:success]).to be(true)
        expect(result[:bookmaker]).to be_persisted
      end
    end

    context "with invalid params" do
      subject(:result) { described_class.call(user: user, params: params) }

      let(:params) { { name: "Bet365" } }

      before { create(:bookmaker, name: "Bet365", user: user) }

      it "returns errors" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Name has already been taken")
      end
    end
  end
end
