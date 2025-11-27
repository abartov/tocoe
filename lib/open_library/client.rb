# based on this code by @tylercrocker - https://github.com/jayfajardo/openlibrary/issues/36#issuecomment-1087102052
# further adapted to our needs by Asaf Bartov @abartov

class OpenLibrary::Client
  API_URL = 'https://openlibrary.org'

  def initialize
  end

  def request(the_path)
    path = the_path.include?('.json') ? the_path : "#{the_path}.json"
    resp = Net::HTTP.get_response(URI.parse("#{API_URL}#{path}"))
    raise 'FAILED' unless resp.code == '200'

    JSON.parse(resp.body)
  end

  def author olid
    request("/authors/#{olid}")
  end

  def work olid
    request("/works/#{olid}")
  end

  def book olid
    request("/books/#{olid}")
  end

  def search query: nil, author: nil, title: nil, has_fulltext: false, page: 1, per_page: 20
    q = []
    q << "q=#{CGI.escape(query)}" unless query.blank?
    q << "author=#{CGI.escape(author)}" unless author.blank?
    q << "title=#{CGI.escape(title)}" unless title.blank?
    q << "has_fulltext=true" if has_fulltext
    # Request edition information including key, language, and ebook_access
    q << "fields=*,editions,editions.key,editions.language,editions.ebook_access"

    # Add pagination parameters
    # Ensure per_page doesn't exceed API limit of 1000
    limit = [per_page.to_i, 1000].min
    offset = (page.to_i - 1) * limit
    q << "limit=#{limit}"
    q << "offset=#{offset}"

    request("/search.json?#{q.join('&')}")
  end

  # Get Internet Archive identifier(s) for an OpenLibrary book
  # Returns the first IA identifier, or nil if none found
  def ia_identifier(olid)
    book_data = book(olid)
    book_data['ocaid']
  rescue => e
    Rails.logger.error "Failed to get IA identifier for #{olid}: #{e.message}"
    nil
  end

  # Get scan metadata from Internet Archive
  # Returns hash with imagecount and other metadata, or nil on failure
  def ia_metadata(ia_id)
    return nil if ia_id.blank?

    uri = URI.parse("https://archive.org/metadata/#{ia_id}")
    resp = Net::HTTP.get_response(uri)
    return nil unless resp.code == '200'

    data = JSON.parse(resp.body)
    {
      imagecount: data['metadata']['imagecount']&.to_i,
      title: data['metadata']['title'],
      page_progression: data['metadata']['page-progression']
    }
  rescue => e
    Rails.logger.error "Failed to get IA metadata for #{ia_id}: #{e.message}"
    nil
  end

  # Get list of page image URLs for an Internet Archive identifier
  # Options:
  #   - start_page: first page number (default: 0)
  #   - end_page: last page number (default: imagecount - 1)
  #   - scale: image scale (default: nil, can be a number like 2, 4, 8)
  # Returns array of hashes with page_number and url
  def ia_page_images(ia_id, options = {})
    return [] if ia_id.blank?

    metadata = ia_metadata(ia_id)
    return [] unless metadata && metadata[:imagecount]

    imagecount = metadata[:imagecount]
    start_page = options[:start_page] || 0
    end_page = options[:end_page] || (imagecount - 1)
    scale = options[:scale]

    pages = []
    (start_page..end_page).each do |n|
      url = page_image_url(ia_id, n, scale)
      pages << {
        page_number: n,
        url: url,
        thumb_url: page_image_url(ia_id, n, 8) # Always provide thumbnail at scale=8
      }
    end

    pages
  end

  private

  # Construct URL for a specific page image
  # scale: optional scale parameter (e.g., 2, 4, 8 for smaller images)
  def page_image_url(ia_id, page_num, scale = nil)
    base = "https://archive.org/download/#{ia_id}/page/n#{page_num}.jpg"
    scale ? "#{base}?scale=#{scale}" : base
  end
end