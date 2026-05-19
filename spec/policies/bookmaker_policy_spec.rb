require "rails_helper"

RSpec.describe BookmakerPolicy do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }

  let(:bookmaker) do
    create(:bookmaker, user: owner)
  end

  describe "#show?" do
    it "allows access for owner" do
      policy = described_class.new(owner, bookmaker)

      expect(policy.show?).to be(true)
    end

    it "denies access for non-owner" do
      policy = described_class.new(other_user, bookmaker)

      expect(policy.show?).to be(false)
    end
  end

  describe "#update?" do
    it "allows access for owner" do
      policy = described_class.new(owner, bookmaker)

      expect(policy.update?).to be(true)
    end

    it "denies access for non-owner" do
      policy = described_class.new(other_user, bookmaker)

      expect(policy.update?).to be(false)
    end
  end

  describe "#destroy?" do
    it "allows access for owner" do
      policy = described_class.new(owner, bookmaker)

      expect(policy.destroy?).to be(true)
    end

    it "denies access for non-owner" do
      policy = described_class.new(other_user, bookmaker)

      expect(policy.destroy?).to be(false)
    end
  end

  describe "Scope" do
    let!(:owned_bookmaker) do
      create(:bookmaker, user: owner)
    end

    let!(:other_bookmaker) do
      create(:bookmaker, user: other_user)
    end

    it "returns only owned bookmakers" do
      resolved_scope = described_class::Scope
        .new(owner, Bookmaker.all)
        .resolve

      expect(resolved_scope).to contain_exactly(owned_bookmaker)
    end
  end
end
