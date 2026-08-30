require "rails_helper"

RSpec.describe Author, type: :model do
  it "is valid with a unique name" do
    expect(build(:author)).to be_valid
  end

  it "rejects duplicate names" do
    author = create(:author, name: "Test Chef")

    expect(build(:author, name: author.name)).not_to be_valid
  end

  it "restricts deletion while recipes use it" do
    author = create(:author)
    create(:recipe, author:)

    expect { author.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
