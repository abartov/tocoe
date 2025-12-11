# Gutendex API client for Project Gutenberg catalog
# Based on Gutendex API documentation: https://github.com/garethbjohnson/gutendex

class Gutendex::Client
  def initialize
    @api_url = Rails.configuration.constants['gutendex_api_url'] || 'https://gutendex.toolforge.org'
  end

  def request(the_path, params = {})
    uri = URI.parse("#{@api_url}#{the_path}")
    uri.query = URI.encode_www_form(params) unless params.empty?

    resp = Net::HTTP.get_response(uri)
    raise "FAILED: #{resp.code} #{resp.message}" unless resp.code == '200'

    JSON.parse(resp.body)
  end

  # Get a specific book by Project Gutenberg ID
  def book(pg_id)
    request("/books/#{pg_id}/")
  end

  # Search for books
  # Options:
  #   - query: search author names and book titles (space-separated, case-insensitive)
  #   - topic: search bookshelves or subjects
  #   - author_year_start/author_year_end: filter by author birth/death years
  #   - languages: comma-separated language codes (e.g., 'en', 'fr,de')
  #   - copyright: true (copyrighted), false (public domain), or nil (unknown)
  #   - ids: comma-separated book IDs
  #   - mime_type: filter by MIME type (prefix matching)
  #   - sort: 'ascending', 'descending', or 'popular' (default)
  #   - page: page number for pagination (default: 1)
  #   - per_page: items per page (Gutendex returns max 32 per page)
  def search(query: nil, topic: nil, author_year_start: nil, author_year_end: nil,
             languages: nil, copyright: nil, ids: nil, mime_type: nil,
             sort: nil, page: 1, per_page: 32)
    params = {}
    params[:search] = query unless query.blank?
    params[:topic] = topic unless topic.blank?
    params[:author_year_start] = author_year_start unless author_year_start.blank?
    params[:author_year_end] = author_year_end unless author_year_end.blank?
    params[:languages] = languages unless languages.blank?
    params[:copyright] = copyright unless copyright.nil?
    params[:ids] = ids unless ids.blank?
    params[:mime_type] = mime_type unless mime_type.blank?
    params[:sort] = sort unless sort.blank?

    # Gutendex uses offset-based pagination
    # Calculate offset from page number
    limit = [per_page.to_i, 32].min # Gutendex max is 32
    offset = (page.to_i - 1) * limit
    params[:page] = offset / 32 + 1 if offset > 0

    result = request('/books/', params)

    # Transform response to include pagination info similar to OpenLibrary
    {
      'count' => result['count'],
      'next' => result['next'],
      'previous' => result['previous'],
      'results' => result['results'],
      'numFound' => result['count']
    }
  end

  # Get fulltext URLs for a book
  # Returns hash of format types to URLs
  def fulltext_urls(pg_id)
    book_data = book(pg_id)
    book_data['formats'] || {}
  rescue => e
    Rails.logger.error "Failed to get fulltext URLs for PG ID #{pg_id}: #{e.message}"
    {}
  end

  # Get preferred fulltext URL for a book
  # Prefers HTML, then plain text
  def preferred_fulltext_url(pg_id)
    formats = fulltext_urls(pg_id)

    # Prefer HTML
    html_url = formats['text/html'] || formats.find { |k, _v| k.include?('html') }&.last
    return html_url if html_url

    # Fall back to plain text
    text_url = formats['text/plain'] || formats['text/plain; charset=utf-8'] ||
               formats['text/plain; charset=us-ascii']
    return text_url if text_url

    nil
  rescue => e
    Rails.logger.error "Failed to get preferred fulltext URL for PG ID #{pg_id}: #{e.message}"
    nil
  end
end
