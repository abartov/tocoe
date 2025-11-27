class PublicationsController < ApplicationController
  @@olclient = OpenLibrary::Client.new
  @@gutendex_client = Gutendex::Client.new

  def search
    search_params = params[:search] || params[:q]
    @source = params[:source] || 'openlibrary'

    if search_params.present? || params[:title].present? || params[:author].present?
      # Add pagination parameters
      @current_page = (params[:page] || 1).to_i
      @per_page = (params[:per_page] || 20).to_i

      case @source
      when 'gutendex'
        search_gutendex(search_params)
      else # 'openlibrary'
        search_openlibrary(search_params)
      end
    end
  end

  def details
    @olkey = params[:olkey]
  end

  def browse
  end

  def savetoc
  end

  def olclient
    @@olclient
  end

  private

  def search_openlibrary(search_params)
    # Determine if we should filter for full-text only
    fulltext_only = params[:fulltext_only] == '1' || params[:fulltext_only] == 'true'

    # Build search query
    search_opts = {}
    search_opts[:title] = params[:title] if params[:title].present?
    search_opts[:author] = params[:author] if params[:author].present?
    if search_params.present? && params[:title].blank? && params[:author].blank?
      search_opts[:query] = search_params
    end
    search_opts[:has_fulltext] = fulltext_only
    search_opts[:page] = @current_page
    search_opts[:per_page] = @per_page

    @results = olclient.search(**search_opts)
    @any_fulltext = false
    if @results.present?
      @num_results = @results['numFound']
      @total_pages = (@num_results.to_f / @per_page).ceil
      @results = @results['docs']

      # Filter for public ebook access if fulltext_only is enabled
      if fulltext_only
        @results = @results.select { |r| r['has_fulltext'] && r['ebook_access'] == 'public' }
      end

      # Filter out publications that already have ToCs
      @results = filter_existing_tocs_openlibrary(@results)

      @results.each do |r|
        logger.info "#{r['title']} / #{r['author_name']} #{(r['has_fulltext'] && r['ebook_access'] == 'public') ? '[ebook!]' : 'metadata only'}"
        @any_fulltext = true if r['has_fulltext'] && r['ebook_access'] == 'public'
      end
    end
  end

  def search_gutendex(search_params)
    # Build search query for Gutendex
    search_opts = {}
    if params[:title].present? && params[:author].present?
      # Combine title and author in general search
      search_opts[:query] = "#{params[:title]} #{params[:author]}"
    elsif params[:title].present?
      search_opts[:query] = params[:title]
    elsif params[:author].present?
      search_opts[:query] = params[:author]
    elsif search_params.present?
      search_opts[:query] = search_params
    end

    # Gutendex only has public domain books, so all results have fulltext
    search_opts[:page] = @current_page
    search_opts[:per_page] = @per_page

    response = gutendex_client.search(**search_opts)
    @any_fulltext = true # All Gutendex books have fulltext
    if response.present?
      @num_results = response['numFound']
      @total_pages = (@num_results.to_f / @per_page).ceil
      @results = response['results'] || []

      # Transform Gutendex results to a common format
      @results = @results.map do |book|
        {
          'id' => book['id'],
          'title' => book['title'],
          'author_name' => book['authors']&.map { |a| a['name'] },
          'has_fulltext' => true,
          'ebook_access' => 'public',
          'source' => 'gutendex',
          'formats' => book['formats']
        }
      end

      # Filter out publications that already have ToCs
      @results = filter_existing_tocs_gutendex(@results)
    end
  end

  def gutendex_client
    @@gutendex_client
  end

  # Filter out search results that already have ToC entries in the database
  # @param results [Array<Hash>] OpenLibrary search results
  # @return [Array<Hash>] Filtered results without existing ToCs
  def filter_existing_tocs_openlibrary(results)
    return results if results.blank?

    # Extract edition keys from results
    edition_keys = results.filter_map do |book|
      edition = book.dig('editions', 'docs')&.first
      edition&.dig('key')&.split('/')&.last
    end

    return results if edition_keys.empty?

    # Build book URIs to check against existing ToCs
    book_uris = edition_keys.map { |key| "http://openlibrary.org/books/#{key}" }

    # Query existing ToCs with these URIs
    existing_uris = Toc.where(book_uri: book_uris).pluck(:book_uri).to_set

    # Filter out results that have existing ToCs
    results.reject do |book|
      edition = book.dig('editions', 'docs')&.first
      edition_key = edition&.dig('key')&.split('/')&.last
      next false unless edition_key

      book_uri = "http://openlibrary.org/books/#{edition_key}"
      existing_uris.include?(book_uri)
    end
  end

  # Filter out Gutendex results that already have ToCs
  # @param results [Array<Hash>] Gutendex search results
  # @return [Array<Hash>] Filtered results without existing ToCs
  def filter_existing_tocs_gutendex(results)
    return results if results.blank?

    # Build book URIs for Gutendex books
    book_uris = results.map { |book| "https://www.gutenberg.org/ebooks/#{book['id']}" }

    # Query existing ToCs with these URIs
    existing_uris = Toc.where(book_uri: book_uris).pluck(:book_uri).to_set

    # Filter out results that have existing ToCs
    results.reject do |book|
      book_uri = "https://www.gutenberg.org/ebooks/#{book['id']}"
      existing_uris.include?(book_uri)
    end
  end
end
