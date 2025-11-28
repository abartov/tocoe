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
        result[:label]&.strip&.downcase == normalized_query
      end
    end

    private

    def parse_search_results(data)
      return [] unless data.is_a?(Array)

      # Find all atom:entry elements in the feed
      entries = find_elements_by_tag(data, 'atom:entry')

      entries.map do |entry|
        # Extract title from atom:title element
        title_element = find_element_by_tag(entry, 'atom:title')
        label = extract_text_content(title_element)

        # Extract URI from atom:link element with rel="alternate"
        link_element = find_link_by_rel(entry, 'alternate')
        uri = extract_href(link_element)

        # Only include results that have both uri and label
        next if uri.nil? || uri.empty? || label.nil? || label.empty?

        {
          uri: uri,
          label: label
        }
      end.compact
    end

    # Find all elements with a given tag name in a nested array structure
    def find_elements_by_tag(data, tag_name)
      return [] unless data.is_a?(Array)

      results = []
      data.each do |element|
        next unless element.is_a?(Array) && element.length > 0

        # Check if this element matches the tag
        results << element if element[0] == tag_name

        # Recursively search children (elements after the first two: tag and attributes)
        element[2..-1]&.each do |child|
          results.concat(find_elements_by_tag(child, tag_name)) if child.is_a?(Array)
        end
      end
      results
    end

    # Find first element with a given tag name
    def find_element_by_tag(element, tag_name)
      return nil unless element.is_a?(Array)

      element[2..-1]&.find { |child| child.is_a?(Array) && child[0] == tag_name }
    end

    # Find first atom:link element with specific rel attribute
    def find_link_by_rel(element, rel_value)
      return nil unless element.is_a?(Array)

      element[2..-1]&.find do |child|
        child.is_a?(Array) &&
        child[0] == 'atom:link' &&
        child[1].is_a?(Hash) &&
        child[1]['rel'] == rel_value
      end
    end

    # Extract text content from an element (third position in array)
    def extract_text_content(element)
      return nil unless element.is_a?(Array) && element.length > 2

      element[2].is_a?(String) ? element[2] : nil
    end

    # Extract href attribute from a link element
    def extract_href(element)
      return nil unless element.is_a?(Array) && element.length > 1 && element[1].is_a?(Hash)

      element[1]['href']
    end
  end
end
