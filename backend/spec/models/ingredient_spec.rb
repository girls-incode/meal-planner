require "rails_helper"

RSpec.describe Ingredient, type: :model do
  it "is valid with a unique name" do
    expect(build(:ingredient, name: "flour")).to be_valid
  end

  it "is invalid with a duplicate name, case-insensitively" do
    create(:ingredient, name: "Flour")
    expect(build(:ingredient, name: "flour")).not_to be_valid
  end

  describe ".search" do
    it "matches ingredients case-insensitively by partial name" do
      matching = create(:ingredient, name: "yellow cornmeal")
      create(:ingredient, name: "sugar")

      expect(Ingredient.search("CORN")).to contain_exactly(matching)
    end
  end
end
