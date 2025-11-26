# Wikidata API client for searching entities
# Uses the wbsearchentities Action API
# Documentation: https://www.wikidata.org/w/api.php?action=help&modules=wbsearchentities

module SubjectHeadings
  class WikidataClient
    API_URL = 'https://www.wikidata.org/w/api.php'

    def initialize
    end

    # Search for Wikidata entities (items) by keyword
    # @param query [String] The search term
    # @param count [Integer] Number of results to return
    # @return [Array<Hash>] Array of hashes with :uri and :label keys
    def search(query, count: 20)
      return [] if query.blank?

      params = {
        action: 'wbsearchentities',
        search: CGI.escape(query),
        format: 'json',
        language: 'en',
        uselang: 'en',
        type: 'item',
        limit: count
      }

      url = "#{API_URL}?#{params.map { |k, v| "#{k}=#{v}" }.join('&')}"

      begin
        resp = Net::HTTP.get_response(URI.parse(url))
        raise "Wikidata API request failed with status #{resp.code}" unless resp.code == '200'

        data = JSON.parse(resp.body)

        # The wbsearchentities API returns a 'search' array
        # Each result contains: id, label, description, and other metadata
        results = data['search'] || []

        results.map do |result|
          {
            uri: "http://www.wikidata.org/entity/#{result['id']}",
            label: result['label'] || result['id']
          }
        end
      rescue StandardError => e
        Rails.logger.error("Wikidata API error: #{e.message}")
        []
      end
    end
  end
end
