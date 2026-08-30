require "uri"

class UnwrapRemainingRecipeImageUrls < ActiveRecord::Migration[8.1]
  def up
    rows = connection.select_all(<<~SQL)
      SELECT id, image_url
      FROM recipes
      WHERE image_url LIKE 'https://imagesvc.meredithcorp.io/v3/mm/image?%'
    SQL

    rows.each do |row|
      encoded_url = URI.parse(row["image_url"]).query.to_s.split("&").find { |part| part.start_with?("url=") }&.delete_prefix("url=")
      next unless encoded_url

      original_url = URI::DEFAULT_PARSER.escape(URI.decode_www_form_component(encoded_url))
      next unless valid_url?(original_url)

      connection.execute(
        "UPDATE recipes SET image_url = #{connection.quote(original_url)} WHERE id = #{connection.quote(row["id"])}"
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "original Meredith proxy URLs are not recoverable"
  end

  private

  def valid_url?(value)
    uri = URI.parse(value)
    uri.is_a?(URI::HTTP) && uri.host.present? && value.length <= 2_048
  rescue URI::InvalidURIError
    false
  end
end
