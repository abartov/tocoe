# frozen_string_literal: true

require 'httparty'
require 'cgi'

module Viaf
  # Client for interacting with VIAF (Virtual International Authority File) API
  class Client
    include HTTParty
    base_uri 'http://viaf.org'

    # Search for persons by name using VIAF AutoSuggest
    # Returns array of results with viaf_id and label
    #
    # @param query [String] Person name to search for
    # @return [Array<Hash>] Array of { viaf_id: Integer, label: String }
    def search_person(query)
      return [] if query.nil? || query.strip.empty?

      response = self.class.get("/viaf/AutoSuggest?query=#{CGI.escape(query)}")
      return [] unless response.success?

      data = JSON.parse(response.body)
      parse_results(data)
    rescue StandardError => e
      Rails.logger.error "VIAF API error: #{e.message}"
      []
    end

    private

    def parse_results(data)
      return [] unless data.is_a?(Hash) && data['result'].is_a?(Array)

      results = data['result'].filter_map do |item|
        next unless item['viafid'].present?

        {
          viaf_id: item['viafid'].to_i,
          label: item['term'] || item['displayForm'] || "VIAF ID: #{item['viafid']}"
        }
      end

      # Limit results to 30 items
      results.take(30)
    end
  end
end
