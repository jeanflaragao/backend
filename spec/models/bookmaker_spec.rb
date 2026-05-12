require "rails_helper"

RSpec.describe Bookmaker, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      bookmaker = build(:bookmaker)

      expect(bookmaker).to be_valid
    end

    it "is invalid without a name" do
      bookmaker = build(:bookmaker, name: nil)

      expect(bookmaker).not_to be_valid
      expect(bookmaker.errors[:name]).to include("can't be blank")
    end
  end
end
