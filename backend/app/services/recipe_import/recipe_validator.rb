# typed: true
# frozen_string_literal: true

require "uri"
require "nokogiri"

module RecipeImport
  class RecipeValidator
    extend T::Sig
    MAX_TITLE_LENGTH = 255
    MAX_INGREDIENTS = 500
    MAX_IMAGE_URL_LENGTH = 2_048
    IMAGE_PROXY_HOST = "imagesvc.meredithcorp.io"
    IMAGE_PROXY_PATH = "/v3/mm/image"

    sig { params(record: T.untyped).returns(T::Boolean) }
    def self.valid?(record)
      decoded_title = title(record["title"]) if record.is_a?(Hash) && record["title"].is_a?(String)

      record.is_a?(Hash) && decoded_title.present? && decoded_title.length <= MAX_TITLE_LENGTH &&
        record["ingredients"].is_a?(Array) &&
        record["ingredients"].present? && record["ingredients"].size <= MAX_INGREDIENTS
    end

    sig { params(record: T::Hash[String, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
    def self.attributes(record)
      {
        title: title(record["title"]),
        prep_time_minutes: non_negative_integer(record["prep_time"]),
        cook_time_minutes: non_negative_integer(record["cook_time"]),
        ratings: non_negative_float(record["ratings"]), cuisine: unescaped(record["cuisine"]),
        image_url: image_url(record["image"])
      }
    end

    sig { params(record: T::Hash[String, T.untyped]).returns(T.nilable(String)) }
    def self.category_name(record)
      unescaped(record["category"])
    end

    sig { params(record: T::Hash[String, T.untyped]).returns(T.nilable(String)) }
    def self.author_name(record)
      unescaped(record["author"])
    end

    sig { params(value: T.untyped).returns(T.nilable(String)) }
    def self.unescaped(value)
      unescape_html(value.to_s.strip).presence
    end

    sig { params(value: String).returns(String) }
    def self.title(value)
      unescape_html(value.strip)
    end

    # CGI.unescapeHTML only decodes amp/lt/gt/quot/apos, so named entities like
    # "&reg;" or "&copy;" pass through untouched. Nokogiri knows the full HTML5
    # entity set, so round-trip the string through it; this also strips any
    # literal HTML tags from the source data, which is the desired behavior for
    # display names like recipe titles, categories, and authors.
    sig { params(value: String).returns(String) }
    def self.unescape_html(value)
      Nokogiri::HTML.fragment(value).text
    end

    sig { params(value: T.untyped).returns(T.nilable(String)) }
    def self.image_url(value)
      uri = URI.parse(value.to_s)
      if uri.host == IMAGE_PROXY_HOST && uri.path == IMAGE_PROXY_PATH
        encoded_url = URI.decode_www_form(uri.query.to_s).to_h["url"]
        value = URI::DEFAULT_PARSER.escape(URI.decode_www_form_component(encoded_url.to_s))
        uri = URI.parse(value)
      end

      value if uri.is_a?(URI::HTTP) && uri.host.present? && value.length <= MAX_IMAGE_URL_LENGTH
    rescue URI::InvalidURIError
      nil
    end

    sig { params(value: T.untyped).returns(T.nilable(Integer)) }
    def self.non_negative_integer(value)
      return value if value.is_a?(Integer) && value >= 0
      return unless value.is_a?(String) && value.match?(/\A\d+\z/)

      value.to_i
    end

    sig { params(value: T.untyped).returns(T.nilable(Float)) }
    def self.non_negative_float(value)
      number = Float(value)
      number if number.finite? && number >= 0
    rescue ArgumentError, TypeError
      nil
    end

    private_class_method :non_negative_integer, :non_negative_float, :unescaped, :unescape_html, :title
  end
end
