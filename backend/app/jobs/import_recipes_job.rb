require "net/http"
require "tempfile"
require "uri"
require "zlib"
require "digest"

class ImportRecipesJob < ApplicationJob
  queue_as :default

  MAX_DOWNLOAD_BYTES = 20.megabytes
  HTTP_TIMEOUT = 30
  GZIP_CONTENT_TYPE = %r{application/(?:gzip|x-gzip)|octet-stream}i

  def perform(source_url: nil, file_path: nil)
    return RecipeSeeder.call(file: file_path, source_url:) if file_path

    source_url ||= ENV.fetch("RECIPES_SOURCE_URL")

    Tempfile.create([ "recipes", ".json.gz" ], binmode: true) do |compressed|
      download(source_url, compressed)
      compressed.flush
      # RecipeSeeder makes two passes (catalog then batches). Each pass reads
      # a bounded JSON payload into memory before parsing it.
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
        raise ArgumentError, "source is not gzip content" unless content_type.empty? || content_type.match?(GZIP_CONTENT_TYPE)
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
