require "net/http"
require "tempfile"
require "uri"
require "zlib"
require "digest"

class ImportRecipesJob < ApplicationJob
  queue_as :default

  DEFAULT_SOURCE_URL = "https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz"
  MAX_DOWNLOAD_BYTES = 500.megabytes
  HTTP_TIMEOUT = 30

  def perform(source_url: DEFAULT_SOURCE_URL, file_path: nil)
    return RecipeSeeder.call(file: file_path, source_url:) if file_path

    Tempfile.create([ "recipes", ".json.gz" ]) do |compressed|
      download(source_url, compressed)
      compressed.flush
      # RecipeSeeder makes two passes (catalog then batches); each pass opens
      # the gzip stream directly, so neither the compressed payload nor its
      # expanded JSON array is materialized in memory.
      RecipeSeeder.call(
        source_url:,
        source_fingerprint: Digest::SHA256.file(compressed.path).hexdigest,
        io_factory: ->(&block) { Zlib::GzipReader.open(compressed.path, &block) }
      )
    end
  end

  private

  def download(source_url, destination)
    uri = URI.parse(source_url)
    raise ArgumentError, "source_url must use https" unless uri.is_a?(URI::HTTPS)

    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: HTTP_TIMEOUT, read_timeout: HTTP_TIMEOUT) do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |response|
        response.value
        content_type = response["content-type"].to_s
        raise ArgumentError, "source is not gzip content" unless content_type.empty? || content_type.match?(%r{application/(?:gzip|x-gzip)|octet-stream}i)
        content_length = response["content-length"].to_i
        raise ArgumentError, "source exceeds #{MAX_DOWNLOAD_BYTES} bytes" if content_length > MAX_DOWNLOAD_BYTES

        downloaded = 0
        response.read_body do |chunk|
          downloaded += chunk.bytesize
          raise ArgumentError, "source exceeds #{MAX_DOWNLOAD_BYTES} bytes" if downloaded > MAX_DOWNLOAD_BYTES

          destination.write(chunk)
        end
      end
    end
  end
end
