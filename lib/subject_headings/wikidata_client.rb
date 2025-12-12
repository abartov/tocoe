# Wikidata API client for searching entities
# Uses the wbsearchentities Action API
# Documentation: https://www.wikidata.org/w/api.php?action=help&modules=wbsearchentities

require 'net/http'
require 'uri'

module SubjectHeadings
  class WikidataClient
    API_URL = 'https://www.wikidata.org/w/api.php'

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

    # Search for Wikidata entities (items) by keyword
    # @param query [String] The search term
    # @param count [Integer] Number of results to return
    # @return [Array<Hash>] Array of hashes with :uri, :label, and :instance_of labels
    def search(query, count: 20)
      return [] if query.blank?

      params = {
        action: 'wbsearchentities',
        search: query,
        format: 'json',
        language: 'en',
        uselang: 'en',
        type: 'item',
        limit: count
      }

      begin
        data = fetch_json(params)
        results = data['search'] || []
        return [] if results.empty?

        entity_ids = results.map { |result| result['id'] }
        entity_details = fetch_entities(entity_ids)
        instance_ids_by_entity = entity_ids.each_with_object({}) do |entity_id, memo|
          memo[entity_id] = instance_of_ids_from(entity_details[entity_id])
        end

        instance_value_ids = instance_ids_by_entity.values.flatten.uniq
        instance_labels = fetch_labels(instance_value_ids)

        results.map do |result|
          entity_id = result['id']
          instance_labels_for_entity = instance_ids_by_entity.fetch(entity_id, []).map do |value_id|
            instance_labels[value_id]
          end.compact

          {
            uri: "http://www.wikidata.org/entity/#{entity_id}",
            label: result['label'] || result['id'],
            instance_of: instance_labels_for_entity
          }
        end
      rescue StandardError => e
        Rails.logger.error("Wikidata API error: #{e.message}")
        []
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

    def instance_of_ids_from(entity)
      return [] unless entity.is_a?(Hash)

      claims = entity.dig('claims', 'P31') || []
      claims.map do |claim|
        claim.dig('mainsnak', 'datavalue', 'value', 'id')
      end.compact.uniq
    end
  end
end
