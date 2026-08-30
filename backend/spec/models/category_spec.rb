require "rails_helper"

RSpec.describe Category, type: :model do
  it "is valid with a unique name" do
    expect(build(:category)).to be_valid
  end

  it "rejects duplicate names" do
    category = create(:category, name: "Dinner")

    expect(build(:category, name: category.name)).not_to be_valid
  end

  it "restricts deletion while recipes use it" do
    category = create(:category)
    create(:recipe, category:)

    expect { category.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
