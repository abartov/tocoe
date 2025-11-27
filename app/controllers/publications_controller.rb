class PublicationsController < ApplicationController
  @@olclient = OpenLibrary::Client.new
  def search
    search_params = params[:search] || params[:q]

    if search_params.present? || params[:title].present? || params[:author].present?
      # Determine if we should filter for full-text only
      fulltext_only = params[:fulltext_only] == '1' || params[:fulltext_only] == 'true'

      # Build search query
      search_opts = {}
      if params[:title].present?
        search_opts[:title] = params[:title]
      end
      if params[:author].present?
        search_opts[:author] = params[:author]
      end
      if search_params.present? && params[:title].blank? && params[:author].blank?
        search_opts[:query] = search_params
      end
      search_opts[:has_fulltext] = fulltext_only

      @results = olclient.search(**search_opts)
      @any_fulltext = false
      if @results.present?
        @num_results = @results['numFound']
        @results = @results['docs']

        # Filter for public ebook access if fulltext_only is enabled
        if fulltext_only
          @results = @results.select { |r| r['has_fulltext'] && r['ebook_access'] == 'public' }
          @num_results = @results.length
        end

        # Filter out publications that already have ToCs
        @results = filter_existing_tocs(@results)

        @results.each {|r| logger.info "#{r['title']} / #{r['author_name']} #{(r['has_fulltext'] && r['ebook_access'] == 'public') ? "[ebook!]" : "metadata only"}"
          @any_fulltext = true if r['has_fulltext'] && r['ebook_access'] == 'public'
        }
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

  # Filter out search results that already have ToC entries in the database
  # @param results [Array<Hash>] OpenLibrary search results
  # @return [Array<Hash>] Filtered results without existing ToCs
  def filter_existing_tocs(results)
    return results if results.blank?

    # Extract edition keys from results
    # Each result may have editions.docs array with keys like "/books/OL123M"
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
end
