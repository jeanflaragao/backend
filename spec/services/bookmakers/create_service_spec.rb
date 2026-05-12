require "rails_helper"

RSpec.describe Bookmakers::CreateService do
  describe ".call" do
    context "with valid params" do
      it "creates a bookmaker" do
        result = described_class.call(
          params: {
            name: "Bet365"
          }
        )

        expect(result[:success]).to eq(true)
        expect(result[:bookmaker]).to be_persisted
      end
    end

    context "with invalid params" do
      it "returns errors" do
        create(:bookmaker, name: "Bet365")

        result = described_class.call(
          params: {
            name: "Bet365"
          }
        )

        expect(result[:success]).to eq(false)
        expect(result[:errors]).to include(
          "Name has already been taken"
        )
      end
    end
  end
end