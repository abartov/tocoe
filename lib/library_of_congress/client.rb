# frozen_string_literal: true

require 'httparty'

module LibraryOfCongress
  # Client for interacting with Library of Congress Subject Headings API
  class Client
    include HTTParty
    base_uri 'https://id.loc.gov'

    # Search for subject headings by label
    # Returns array of results with uri, label, and other metadata
    def search_subjects(query)
      # Normalize query: replace ' -- ' with '--' per LC norms
      normalized_query = query.gsub(' -- ', '--')

      # Search the LC subject headings
      # Use 'cs' parameter to limit to subject headings collection
      response = self.class.get('/search/', query: {
        q: "#{normalized_query} cs:http://id.loc.gov/authorities/subjects",
        format: 'json'
      })

      return [] unless response.success?

      data = JSON.parse(response.body)
      parse_search_results(data)
    rescue StandardError => e
      Rails.logger.error "LC API search error: #{e.message}"
      []
    end

    # Find exact match for a subject heading
    # Returns hash with uri and label if exact match found, nil otherwise
    def find_exact_match(query)
      results = search_subjects(query)
      normalized_query = query.gsub(' -- ', '--').strip.downcase

      results.find do |result|
        result[:label].strip.downcase == normalized_query
      end
    end

    private

    def parse_search_results(data)
      return [] unless data.is_a?(Array)

      data.map do |item|
        next unless item.is_a?(Hash)

        {
          uri: item['uri'],
          label: item['label'] || item['aLabel'],
          score: item['score']
        }
      end.compact
    end
  end
end
