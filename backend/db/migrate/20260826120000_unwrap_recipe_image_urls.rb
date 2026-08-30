require "uri"

class UnwrapRecipeImageUrls < ActiveRecord::Migration[8.1]
  PROXY_HOST = "imagesvc.meredithcorp.io"
  PROXY_PATH = "/v3/mm/image"

  def up
    say_with_time "Unwrapping Meredith image proxy URLs" do
      rows = connection.select_all(<<~SQL)
        SELECT id, image_url
        FROM recipes
        WHERE image_url LIKE 'https://#{PROXY_HOST}#{PROXY_PATH}?%'
      SQL

      rows.each do |row|
        original_url = original_url(row["image_url"])
        next unless valid_url?(original_url)

        connection.execute(
          "UPDATE recipes SET image_url = #{connection.quote(original_url)} WHERE id = #{connection.quote(row["id"])}"
        )
      end
      rows.to_a.size
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "original Meredith proxy URLs are not recoverable"
  end

  private

  def original_url(value)
    uri = URI.parse(value)
    encoded_url = URI.decode_www_form(uri.query.to_s).to_h["url"]
    encoded_url && URI.decode_www_form_component(encoded_url)
  rescue URI::InvalidURIError
    nil
  end

  def valid_url?(value)
    uri = URI.parse(value.to_s)
    uri.is_a?(URI::HTTP) && uri.host.present? && value.length <= 2_048
  rescue URI::InvalidURIError
    false
  end
end
