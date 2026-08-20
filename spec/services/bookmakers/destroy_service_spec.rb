require "rails_helper"

RSpec.describe Bookmakers::DestroyService do
  describe ".call" do
    let(:bookmaker) { create(:bookmaker) }

    it "destroys the supplied bookmaker" do
      expect {
        described_class.call(bookmaker:)
      }.to change(Bookmaker, :count).by(-1)
        .and change { Bookmaker.exists?(bookmaker.id) }
        .from(true).to(false)
    end
  end
end
