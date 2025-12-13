# frozen_string_literal: true

require 'httparty'
require 'cgi'

module LibraryOfCongress
  # Client for interacting with Library of Congress Name Authority API
  class NameAuthorityClient
    include HTTParty
    base_uri 'https://id.loc.gov'

    # Search for persons/names using LC Name Authority suggest2 API
    # Returns array of results with loc_id and label
    #
    # @param query [String] Person name to search for
    # @return [Array<Hash>] Array of { loc_id: String, label: String }
    def search_person(query)
      return [] if query.nil? || query.strip.empty?

      response = self.class.get("/authorities/names/suggest2/?q=#{CGI.escape(query)}")
      return [] unless response.success?

      data = JSON.parse(response.body)
      parse_results(data)
    rescue StandardError => e
      Rails.logger.error "Library of Congress Name Authority API error: #{e.message}"
      []
    end

    private

    def parse_results(data)
      return [] unless data.is_a?(Array)

      results = data.filter_map do |item|
        next unless item['uri'].present? && item['label'].present?

        # Extract ID from URI
        # Example: "info:lc/authorities/names/n79021164" -> "n79021164"
        # Or: "http://id.loc.gov/authorities/names/n79021164" -> "n79021164"
        loc_id = extract_id_from_uri(item['uri'])
        next unless loc_id

        {
          loc_id: loc_id,
          label: item['label']
        }
      end

      # Limit results to 30 items
      results.take(30)
    end

    def extract_id_from_uri(uri)
      # Handle both formats:
      # info:lc/authorities/names/n79021164
      # http://id.loc.gov/authorities/names/n79021164
      return nil if uri.nil? || uri.empty?

      # Remove trailing slashes before splitting
      uri = uri.chomp('/')

      # Split by '/' and get the last segment
      segments = uri.split('/')
      id = segments.last

      # Return the ID only if it looks valid (not empty and not a URL component)
      id.present? && !id.start_with?('http') ? id : nil
    end
  end
end
