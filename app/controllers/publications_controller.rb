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

      if @results.present?
        @num_results = @results['numFound']
        @results = @results['docs']

        # Filter for public ebook access if fulltext_only is enabled
        if fulltext_only
          @results = @results.select { |r| r['has_fulltext'] && r['ebook_access'] == 'public' }
          @num_results = @results.length
        end

        @results.each {|r| logger.info "#{r['title']} / #{r['author_name']} #{(r['has_fulltext'] && r['ebook_access'] == 'public') ? "[ebook!]" : "metadata only"}"}
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
end
