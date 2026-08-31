# frozen_string_literal: true

require "rails_helper"
require "stringio"

RSpec.describe RecipeImport::JsonArrayStream do
  it "streams objects from a top-level JSON array" do
    records = described_class.each(StringIO.new('[{"title":"one"},{"title":"two"}]')).to_a

    expect(records).to eq([ { "title" => "one" }, { "title" => "two" } ])
  end

  it "streams strings containing escaped quotes" do
    records = described_class.each(StringIO.new('[{"title":"1/2\\\" coins"},{"title":"two"}]')).to_a

    expect(records).to eq([ { "title" => '1/2" coins' }, { "title" => "two" } ])
  end

  it "rejects a non-array document" do
    expect {
      described_class.each(StringIO.new('{"title":"one"}')).to_a
    }.to raise_error(JSON::ParserError, "expected a top-level JSON array")
  end

  it "rejects content after the top-level array" do
    expect {
      described_class.each(StringIO.new('[{"title":"one"}] trailing')).to_a
    }.to raise_error(JSON::ParserError, "unexpected content after top-level JSON array")
  end
end
