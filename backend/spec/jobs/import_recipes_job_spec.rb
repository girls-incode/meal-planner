require "rails_helper"
require "stringio"
require "zlib"

RSpec.describe ImportRecipesJob do
  it "downloads gzip bytes without transcoding them" do
    source_url = "https://example.test/recipes.json.gz"
    payload = StringIO.new.tap do |buffer|
      Zlib::GzipWriter.wrap(buffer) { |gzip| gzip.write('[{"title":"Soup"}]') }
    end.string
    response = instance_double(Net::HTTPOK)
    http = instance_double(Net::HTTP)

    allow(Net::HTTP).to receive(:start).and_yield(http)
    allow(http).to receive(:request) { |_request, &block| block.call(response) }
    allow(response).to receive(:value)
    allow(response).to receive(:[]).with("content-type").and_return("application/gzip")
    allow(response).to receive(:[]).with("content-length").and_return(payload.bytesize.to_s)
    allow(response).to receive(:read_body) { |&block| block.call(payload) }
    allow(ENV).to receive(:fetch).with("RECIPES_SOURCE_URL").and_return(source_url)

    expect(RecipeSeeder).to receive(:call) do |source_url:, source_fingerprint:, io_factory:|
      expect(source_url).to eq("https://example.test/recipes.json.gz")
      expect(source_fingerprint).to eq(Digest::SHA256.hexdigest(payload))
      io_factory.call { |io| expect(io.read).to eq('[{"title":"Soup"}]') }
    end

    described_class.perform_now
  end

  it "imports a local file without reading the remote source setting" do
    expect(ENV).not_to receive(:fetch).with("RECIPES_SOURCE_URL")
    expect(RecipeSeeder).to receive(:call).with(file: "/tmp/recipes.json", source_url: nil)

    described_class.perform_now(file_path: "/tmp/recipes.json")
  end

  it "rejects a compressed source larger than the download limit" do
    response = instance_double(Net::HTTPOK)
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:start).and_yield(http)
    allow(http).to receive(:request) { |_request, &block| block.call(response) }
    allow(response).to receive(:value)
    allow(response).to receive(:[]).with("content-type").and_return("application/gzip")
    allow(response).to receive(:[]).with("content-length").and_return((described_class::MAX_DOWNLOAD_BYTES + 1).to_s)
    expect(response).not_to receive(:read_body)

    expect {
      described_class.perform_now(source_url: "https://example.test/recipes.json.gz")
    }.to raise_error(ArgumentError, "source exceeds #{described_class::MAX_DOWNLOAD_BYTES} bytes")
  end
end
