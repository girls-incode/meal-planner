require "rails_helper"

RSpec.describe Ingredients::LineParser do
  describe ".call" do
    it "removes a unitless quantity written with a Unicode fraction slash" do
      lines, issues = described_class.call([ "1⁄2 eggs" ])

      expect(issues).to be_empty
      expect(lines).to contain_exactly(include(name: "eggs", quantity: nil, unit: nil, raw_text: "1⁄2 eggs"))
    end

    it "does not interpret an ingredient's leading letter as a unit" do
      lines, issues = described_class.call([ "ground chicken", "garlic" ])

      expect(issues).to be_empty
      expect(lines).to contain_exactly(
        include(name: "ground chicken", quantity: nil, unit: nil, raw_text: "ground chicken"),
        include(name: "garlic", quantity: nil, unit: nil, raw_text: "garlic")
      )
    end
  end
end
