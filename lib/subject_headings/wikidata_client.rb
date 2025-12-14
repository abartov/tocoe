# Wikidata API client for searching entities
# Uses the wbsearchentities Action API
# Documentation: https://www.wikidata.org/w/api.php?action=help&modules=wbsearchentities

require 'net/http'
require 'uri'

module SubjectHeadings
  class WikidataClient
    API_URL = 'https://www.wikidata.org/w/api.php'
    SPARQL_ENDPOINT = 'https://query.wikidata.org/sparql'

    def initialize
    end

    # Get Library of Congress Authority ID (P244) for a Wikidata entity
    # @param entity_id [String] The Wikidata entity ID (e.g., "Q395")
    # @return [String, nil] The LC authority ID (e.g., "sh85082139"), or nil if not found
    def get_library_of_congress_id(entity_id)
      return nil if entity_id.blank?

      begin
        entity_details = fetch_entities([entity_id])
        entity = entity_details[entity_id]
        return nil unless entity.is_a?(Hash)

        claims = entity.dig('claims', 'P244') || []
        # P244 is a string value, not an entity reference
        claims.first&.dig('mainsnak', 'datavalue', 'value')
      rescue StandardError => e
        Rails.logger.error("Wikidata API error fetching P244: #{e.message}")
        nil
      end
    end

    # Find Wikidata entity by Library of Congress Authority ID (reverse lookup)
    # @param lc_id [String] The LC authority ID (e.g., "sh85082139")
    # @return [Hash, nil] Hash with :entity_id and :label, or nil if not found
    def find_entity_by_library_of_congress_id(lc_id)
      return nil if lc_id.blank?

      begin
        # Use SPARQL query to find entities with this P244 value
        sparql_query = <<~SPARQL
          SELECT ?item ?itemLabel WHERE {
            ?item wdt:P244 "#{lc_id.gsub('"', '\\"')}" .
            SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
          }
          LIMIT 1
        SPARQL

        params = {
          query: sparql_query,
          format: 'json'
        }

        query_string = URI.encode_www_form(params)
        url = "#{SPARQL_ENDPOINT}?#{query_string}"
        uri = URI.parse(url)

        # Make HTTP request with proper User-Agent header (required by Wikimedia)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri.request_uri)
        request['User-Agent'] = 'ToCoE/1.0 (https://github.com/asaf/tocoe)'

        resp = http.request(request)
        return nil unless resp.is_a?(Net::HTTPSuccess)

        data = JSON.parse(resp.body)
        bindings = data.dig('results', 'bindings') || []
        return nil if bindings.empty?

        first_result = bindings.first
        item_uri = first_result.dig('item', 'value')
        label = first_result.dig('itemLabel', 'value')

        return nil unless item_uri

        # Extract entity ID from URI (e.g., "Q395" from "http://www.wikidata.org/entity/Q395")
        entity_id = item_uri.split('/').last

        {
          entity_id: entity_id,
          label: label || entity_id
        }
      rescue StandardError => e
        Rails.logger.error("Wikidata SPARQL error searching for P244=#{lc_id}: #{e.message}")
        nil
      end
    end

    # Search for Wikidata entities (items) by keyword
    # @param query [String] The search term
    # @param count [Integer] Number of results to return
    # @param offset [Integer] Offset for pagination (0-based)
    # @return [Hash] Hash with :results (array) and :has_more (boolean)
    def search(query, count: 20, offset: 0)
      return { results: [], has_more: false } if query.blank?

      params = {
        action: 'wbsearchentities',
        search: query,
        format: 'json',
        language: 'en',
        uselang: 'en',
        type: 'item',
        limit: count,
        continue: offset
      }

      begin
        data = fetch_json(params)
        results = data['search'] || []

        # Check if there are more results available
        # Wikidata returns 'search-continue' in the response if there are more results
        has_more = data.key?('search-continue')

        if results.empty?
          return { results: [], has_more: false }
        end

        entity_ids = results.map { |result| result['id'] }
        entity_details = fetch_entities(entity_ids)
        instance_ids_by_entity = entity_ids.each_with_object({}) do |entity_id, memo|
          memo[entity_id] = instance_of_ids_from(entity_details[entity_id])
        end

        instance_value_ids = instance_ids_by_entity.values.flatten.uniq
        instance_labels = fetch_labels(instance_value_ids)

        # Fetch descriptions for search results
        descriptions = fetch_descriptions(entity_ids)

        formatted_results = results.map do |result|
          entity_id = result['id']
          instance_labels_for_entity = instance_ids_by_entity.fetch(entity_id, []).map do |value_id|
            instance_labels[value_id]
          end.compact

          {
            uri: "http://www.wikidata.org/entity/#{entity_id}",
            label: result['label'] || result['id'],
            description: result['description'] || descriptions[entity_id],
            instance_of: instance_labels_for_entity,
            entity_id: entity_id
          }
        end

        { results: formatted_results, has_more: has_more }
      rescue StandardError => e
        Rails.logger.error("Wikidata API error: #{e.message}")
        { results: [], has_more: false }
      end
    end

    private

    def fetch_json(params)
      query_string = URI.encode_www_form(params)
      url = "#{API_URL}?#{query_string}"
      resp = Net::HTTP.get_response(URI.parse(url))
      raise "Wikidata API request failed with status #{resp.code}" unless resp.is_a?(Net::HTTPSuccess)

      JSON.parse(resp.body)
    end

    def fetch_entities(ids)
      return {} if ids.blank?

      params = {
        action: 'wbgetentities',
        ids: ids.join('|'),
        props: 'claims',
        languages: 'en',
        format: 'json'
      }

      data = fetch_json(params)
      data['entities'] || {}
    end

    def fetch_labels(ids)
      return {} if ids.empty?

      params = {
        action: 'wbgetentities',
        ids: ids.join('|'),
        props: 'labels',
        languages: 'en',
        format: 'json'
      }

      data = fetch_json(params)
      (data['entities'] || {}).each_with_object({}) do |(id, entity), memo|
        label = entity.dig('labels', 'en', 'value')
        memo[id] = label if label
      end
    end

    def fetch_descriptions(ids)
      return {} if ids.empty?

      params = {
        action: 'wbgetentities',
        ids: ids.join('|'),
        props: 'descriptions',
        languages: 'en',
        format: 'json'
      }

      data = fetch_json(params)
      (data['entities'] || {}).each_with_object({}) do |(id, entity), memo|
        description = entity.dig('descriptions', 'en', 'value')
        memo[id] = description if description
      end
    end

    def instance_of_ids_from(entity)
      return [] unless entity.is_a?(Hash)

      claims = entity.dig('claims', 'P31') || []
      claims.map do |claim|
        claim.dig('mainsnak', 'datavalue', 'value', 'id')
      end.compact.uniq
    end
  end
end
