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
    # @param offset [Integer] Starting position for results (0-based)
    # @return [Hash] Hash with :results (array) and :has_more (boolean)
    # Note: The LC suggest2 API doesn't support offset natively, so we fetch a larger
    # batch and slice it client-side. This is not ideal for large offsets but works
    # for reasonable pagination scenarios.
    def search(query, count: 20, offset: 0)
      return { results: [], has_more: false } if query.blank?

      # Fetch more results than needed to determine if there are more pages
      # We fetch offset + count + 1 to check if there are more results
      fetch_count = offset + count + 1

      params = {
        q: CGI.escape(query),
        count: [fetch_count, 1000].min # LC API max is 1000
      }

      url = "#{API_URL}?#{params.map { |k, v| "#{k}=#{v}" }.join('&')}"

      begin
        resp = Net::HTTP.get_response(URI.parse(url))
        raise "LCSH API request failed with status #{resp.code}" unless resp.code == '200'

        data = JSON.parse(resp.body)

        # The suggest2 API returns a JSON object with a 'hits' array
        # Each hit contains: suggestLabel, uri, aLabel, and other metadata
        hits = data['hits'] || []

        # Slice the results based on offset and count
        total_hits = hits.length
        paginated_hits = hits[offset, count] || []

        # Check if there are more results after this page
        has_more = total_hits > (offset + count)

        formatted_results = paginated_hits.map do |hit|
          {
            uri: hit['uri'],
            label: hit['suggestLabel'] || hit['aLabel'],
            # Add additional context from the hit
            alt_labels: [hit['aLabel'], hit['suggestLabel']].compact.uniq.reject { |l| l == (hit['suggestLabel'] || hit['aLabel']) },
            broader: hit['broader'] ? [hit['broader']].flatten : [],
            # LCSH IDs are embedded in the URI (e.g., "sh85082139" from "https://id.loc.gov/authorities/subjects/sh85082139")
            lc_id: hit['uri']&.split('/')&.last
          }
        end

        { results: formatted_results, has_more: has_more }
      rescue StandardError => e
        Rails.logger.error("LCSH API error: #{e.message}")
        { results: [], has_more: false }
      end
    end
  end
end
