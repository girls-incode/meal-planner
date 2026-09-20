require "rails_helper"

RSpec.describe RecipeImport::RecipeValidator do
  describe ".image_url" do
    it "unwraps Meredith image proxy URLs" do
      proxy = "https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fimages.media-allrecipes.com%2Fuserphotos%2F123.jpg"

      expect(described_class.image_url(proxy)).to eq("https://images.media-allrecipes.com/userphotos/123.jpg")
    end

    it "unwraps a proxy URL whose host uses different casing" do
      proxy = "https://IMAGESVC.MEREDITHCORP.IO/v3/mm/image?url=https%3A%2F%2Fimages.media-allrecipes.com%2Fuserphotos%2F123.jpg"

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

    it "rejects a proxy URL with malformed percent-encoding in the wrapped url" do
      proxy = "https://imagesvc.meredithcorp.io/v3/mm/image?url=100%25zz"

      expect(described_class.image_url(proxy)).to be_nil
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

    it "decodes HTML entities in the title and cuisine" do
      attributes = described_class.attributes(
        "title" => "ARGO&reg; Corn Starch",
        "ingredients" => [ "1 egg" ],
        "cuisine" => "Cook&#39;s Country"
      )

      expect(attributes).to include(title: "ARGO® Corn Starch", cuisine: "Cook's Country")
    end

    it "strips whitespace exposed by HTML markup" do
      record = {
        "title" => "<b> Soup </b>", "ingredients" => [ "1 egg" ], "cuisine" => "<i> Home </i>",
        "category" => "<span> Dinner </span>", "author" => "<em> Alice </em>"
      }

      expect(described_class.attributes(record)).to include(title: "Soup", cuisine: "Home")
      expect(described_class.category_name(record)).to eq("Dinner")
      expect(described_class.author_name(record)).to eq("Alice")
    end
  end

  describe ".valid?" do
    it "rejects a title that is blank after HTML tags are removed" do
      record = { "title" => "<br>", "ingredients" => [ "1 egg" ] }

      expect(described_class.valid?(record)).to be(false)
    end
  end

  describe ".category_name" do
    it "decodes HTML entities, including named entities CGI.unescapeHTML does not know" do
      record = { "category" => "ARGO&reg;, KARO&reg;, FLEISCHMANN'S&reg;" }

      expect(described_class.category_name(record)).to eq("ARGO®, KARO®, FLEISCHMANN'S®")
    end

    it "returns nil for a blank category" do
      expect(described_class.category_name({ "category" => "  " })).to be_nil
    end

    it "strips literal HTML tags rather than keeping their markup as visible text" do
      record = { "category" => "Recipes <script>alert(1)</script> Tag" }

      expect(described_class.category_name(record)).to eq("Recipes alert(1) Tag")
    end
  end

  describe ".author_name" do
    it "decodes HTML entities" do
      record = { "author" => "Betty Crocker&reg;" }

      expect(described_class.author_name(record)).to eq("Betty Crocker®")
    end
  end
end
