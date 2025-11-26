# Library of Congress Subject Headings API client
# Uses the LoC Linked Data Service suggest2 API
# Documentation: https://id.loc.gov/techcenter/searching.html

module SubjectHeadings
  class LcshClient
    API_URL = 'https://id.loc.gov/authorities/subjects/suggest2'

    def initialize
    end

    # Search for subject headings by keyword
    # @param query [String] The search term
    # @param count [Integer] Number of results to return (max 1000)
    # @return [Array<Hash>] Array of hashes with :uri and :label keys
    def search(query, count: 20)
      return [] if query.blank?

      params = {
        q: CGI.escape(query),
        count: count
      }

      url = "#{API_URL}?#{params.map { |k, v| "#{k}=#{v}" }.join('&')}"

      begin
        resp = Net::HTTP.get_response(URI.parse(url))
        raise "LCSH API request failed with status #{resp.code}" unless resp.code == '200'

        data = JSON.parse(resp.body)

        # The suggest2 API returns a JSON object with a 'hits' array
        # Each hit contains: suggestLabel, uri, aLabel, and other metadata
        hits = data['hits'] || []

        hits.map do |hit|
          {
            uri: hit['uri'],
            label: hit['suggestLabel'] || hit['aLabel']
          }
        end
      rescue StandardError => e
        Rails.logger.error("LCSH API error: #{e.message}")
        []
      end
    end
  end
end
