require "rails_helper"

RSpec.describe RecipeImport::RecipeValidator do
  describe ".image_url" do
    it "unwraps Meredith image proxy URLs" do
      proxy = "https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fimages.media-allrecipes.com%2Fuserphotos%2F123.jpg"

      expect(described_class.image_url(proxy)).to eq("https://images.media-allrecipes.com/userphotos/123.jpg")
    end

    it "escapes spaces in the original image path" do
      proxy = "https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fpublic-assets.meredithcorp.io%2Fphoto%20name.jpg"

      expect(described_class.image_url(proxy)).to eq("https://public-assets.meredithcorp.io/photo%20name.jpg")
    end

    it "keeps ordinary image URLs" do
      url = "https://example.com/recipe.jpg"

      expect(described_class.image_url(url)).to eq(url)
    end

    it "rejects malformed image URLs" do
      expect(described_class.image_url("not a url")).to be_nil
    end
  end

  describe ".attributes" do
    it "normalizes invalid optional numeric metadata to nil" do
      attributes = described_class.attributes(
        "title" => "Invalid metadata",
        "ingredients" => [ "1 egg" ],
        "ratings" => -1,
        "prep_time" => "unknown",
        "cook_time" => -5
      )

      expect(attributes).to include(ratings: nil, prep_time_minutes: nil, cook_time_minutes: nil)
    end

    it "retains valid non-negative numeric metadata" do
      attributes = described_class.attributes(
        "title" => "Valid metadata",
        "ingredients" => [ "1 egg" ],
        "ratings" => "4.5",
        "prep_time" => "20",
        "cook_time" => 30
      )

      expect(attributes).to include(ratings: 4.5, prep_time_minutes: 20, cook_time_minutes: 30)
    end
  end
end
