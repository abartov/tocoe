require 'uri'
require 'httparty'
require 'rest-client'

# Tables of Contents controller
# rubocop:disable ClassLength
class TocsController < ApplicationController
  before_action :set_toc, only: [:show, :edit, :update, :destroy, :browse_scans, :mark_pages, :mark_transcribed, :verify, :auto_match_subjects]

  # GET /tocs
  # GET /tocs.json
  def index
    # Filter by status if specified
    @tocs = if params[:status].present?
              Toc.where(status: params[:status])
            elsif params[:show_all] == 'true'
              Toc.all
            else
              # By default, show TOCs that need work (exclude verified and current user's TOCs)
              # Include TOCs with no contributor (nil) or TOCs contributed by others
              Toc.where.not(status: :verified)
                 .where("contributor_id IS NULL OR contributor_id != ?", current_user.id)
            end

    # Apply sorting
    @tocs = apply_sorting(@tocs)
  end

  # GET /tocs/search
  def search
    @query = params[:search]

    if @query.blank?
      @tocs = []
      @works = []
      @manifestations = []
    else
      # Search TOCs by title, book_uri, toc_body, and comments
      @tocs = Toc.where(
        'title LIKE ? OR book_uri LIKE ? OR toc_body LIKE ? OR comments LIKE ?',
        "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%"
      ).order(updated_at: :desc).limit(50)

      # Search Works by title
      @works = Work.where('title LIKE ?', "%#{@query}%").order(:title).limit(20)

      # Search Manifestations by title
      @manifestations = Manifestation.where('title LIKE ?', "%#{@query}%").order(:title).limit(20)
    end
  end

  # GET /tocs/1
  # GET /tocs/1.json
  def show
    # @toc = Toc.find(params[:id])
    @manifestation = @toc.manifestation

    # Check if this is a Gutenberg book and fetch fulltext URL
    if @toc.source == 'gutenberg' || @toc.book_uri =~ %r{gutenberg\.org/ebooks/(\d+)}
      pg_book_id = $1
      gutendex_client = Gutendex::Client.new
      @fulltext_url = gutendex_client.preferred_fulltext_url(pg_book_id)
      @is_gutenberg = true
    else
      @is_gutenberg = false
    end
  end

  # GET /tocs/new
  def new
    @toc = Toc.new
    case params[:from]
    when 'openlibrary'
      new_from_openlibrary
    when 'gutendex'
      new_from_gutendex
    end
  end

  def map_authors
    @authors.each_index do |i|
      author = @authors[i]

      # Detect source type by presence of 'key' field
      if author['key']
        # Open Library author format
        p = Person.find_by_openlibrary_id(author['key'])
        if p.nil?
          # create a new Person and link to Open Library ID
          p = Person.new(openlibrary_id: author['key'], name: author['name'])
          p.save!
        end
        @authors[i]['person'] = p
        # Add standardized link field for view layer
        @authors[i]['link'] = "http://openlibrary.org#{p.openlibrary_id}"
      else
        # Gutendex author format (no 'key' field)
        # Find existing Person by name or create new one
        p = Person.find_by(name: author['name'])
        if p.nil?
          p = Person.new(name: author['name'])
          p.save!
        end
        @authors[i]['person'] = p
        # Standardized link field - nil for Gutenberg authors (no author page)
        @authors[i]['link'] = nil
      end
    end
  end

  # GET /tocs/1/edit
  def edit
    # Use stored book_data if available (for Gutendex titles),
    # otherwise fall back to book_uri (for Open Library titles)
    if @toc.book_data.present?
      get_authors(@toc.book_data)
    else
      get_authors(@toc.book_uri)
    end

    # Check if this is a Gutenberg book and fetch fulltext URL
    if @toc.source == 'gutenberg' && @toc.book_uri =~ %r{gutenberg\.org/ebooks/(\d+)}
      pg_book_id = $1
      gutendex_client = Gutendex::Client.new
      @fulltext_url = gutendex_client.preferred_fulltext_url(pg_book_id)
      @is_gutenberg = true
    else
      @is_gutenberg = false
    end
  end

  # POST /tocs
  # POST /tocs.json
  def create
    @toc = Toc.new(toc_params)
    @toc.status = :pages_marked if @toc.book_uri =~ %r{gutenberg\.org/ebooks/(\d+)}
    respond_to do |format|
      if @toc.save
        # Fetch and store authors for the TOC
        if @toc.book_data.present?
          get_authors(@toc.book_data)
        elsif @toc.book_uri.present?
          get_authors(@toc.book_uri)
        end
        store_authors

        format.html { redirect_to @toc, notice: 'Toc was successfully created.' }
        format.json { render :show, status: :created, location: @toc }
      else
        format.html { render :new }
        format.json { render json: @toc.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tocs/1
  # PATCH/PUT /tocs/1.json
  def update
    respond_to do |format|
      if @toc.update(toc_params)
        # Fetch and store authors for the TOC
        if @toc.book_data.present?
          get_authors(@toc.book_data)
        elsif @toc.book_uri.present?
          get_authors(@toc.book_uri)
        end
        store_authors

        format.html { redirect_to @toc, notice: 'Toc was successfully updated.' }
        format.json { render :show, status: :ok, location: @toc }
      else
        format.html { render :edit }
        format.json { render json: @toc.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tocs/1
  # DELETE /tocs/1.json
  def destroy
    unless current_user&.admin?
      flash[:error] = I18n.t('tocs.flash.admin_required')
      redirect_to tocs_url and return
    end

    @toc.destroy
    respond_to do |format|
      format.html { redirect_to tocs_url, notice: 'Toc was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # called via AJAX from tocs#new and tocs#edit
  def do_ocr
    error = false

    # Use provided URLs, or fall back to marked TOC pages if available
    ocr_images_param = params[:ocr_images].to_s.strip
    if ocr_images_param.blank? && params[:toc_id].present?
      toc = Toc.find(params[:toc_id])
      ocr_images_param = toc.toc_page_urls if toc.toc_page_urls.present?
    end

    ocr_images = ocr_images_param.to_s.split
    ocr_images.each do |uri|
      next unless uri =~ /\S/
      error = true unless valid?(uri)
    end
    if error
      @results = '<One or more invalid URLs above>'
    else
      @results = ''
      ocr_images.each do |url|
        next unless url =~ /\S/
        @results += get_ocr_from_service(url) + "\n\n"
      end
    end
  end

  # POST /tocs/:id/auto_match_subjects
  # Auto-match imported subjects with Library of Congress Subject Headings
  def auto_match_subjects
    # Check if TOC has been processed (has manifestation)
    unless @toc.manifestation
      @error = "TOC must be processed first before auto-matching subjects"
      @exact_matches = []
      @suggestions = []
      return
    end

    # Get or ensure main embodiment exists (sequence_number: nil)
    main_embodiment = @toc.manifestation.embodiments.find_by(sequence_number: nil)
    unless main_embodiment
      @error = "Could not find main embodiment for this TOC"
      @exact_matches = []
      @suggestions = []
      return
    end

    # Parse imported subjects
    imported_subjects_array = @toc.imported_subjects.to_s.split("\n").map(&:strip).reject(&:blank?)

    if imported_subjects_array.empty?
      @error = "No imported subjects to match"
      @exact_matches = []
      @suggestions = []
      return
    end

    # Initialize LC client
    lc_client = LibraryOfCongress::Client.new

    @exact_matches = []
    @suggestions = []
    remaining_subjects = []

    imported_subjects_array.each do |subject|
      # Normalize: replace ' -- ' with '--'
      normalized_subject = subject.gsub(' -- ', '--')

      # Search LC API once to get all matches
      search_results = lc_client.search_subjects(normalized_subject)

      if search_results.empty?
        # No matches at all
        remaining_subjects << subject
        next
      end

      # Check if there's an exact match in the results
      normalized_query = normalized_subject.strip.downcase
      exact_match = search_results.find do |result|
        result[:label]&.strip&.downcase == normalized_query
      end

      if exact_match
        # Create Aboutness for exact match
        # Auto-matched subjects are imported (not user-contributed), so they get 'verified' status
        aboutness = Aboutness.new(
          embodiment: main_embodiment,
          subject_heading_uri: exact_match[:uri],
          source_name: 'LCSH',
          subject_heading_label: exact_match[:label],
          status: 'verified',
          contributor_id: nil
        )

        if aboutness.save
          @exact_matches << {
            original_subject: subject,
            matched_label: exact_match[:label],
            uri: exact_match[:uri]
          }
        else
          # If save failed (e.g., duplicate), keep the subject
          remaining_subjects << subject
        end
      else
        # No exact match - show all results as suggestions
        @suggestions << {
          original_subject: subject,
          matches: search_results # All matches, not just top 3
        }
        remaining_subjects << subject
      end
    end

    # Update imported_subjects to remove exact matches
    @toc.imported_subjects = remaining_subjects.join("\n")
    @toc.save

    @error = nil
  end

  # GET /tocs/:id/browse_scans
  # Display book page scans for user to identify TOC pages
  def browse_scans
    # Extract OpenLibrary book ID from book_uri
    if @toc.book_uri =~ %r{openlibrary\.org/books/([A-Z0-9]+)}i
      ol_book_id = $1
    else
      flash[:error] = I18n.t('tocs.flash.invalid_openlibrary_uri')
      redirect_to @toc and return
    end

    # Initialize OpenLibrary client
    ol_client = OpenLibrary::Client.new

    # Get Internet Archive identifier
    @ia_id = ol_client.ia_identifier(ol_book_id)
    unless @ia_id
      flash[:error] = I18n.t('tocs.flash.no_scans_available')
      redirect_to @toc and return
    end

    # Get metadata to determine page count
    @metadata = ol_client.ia_metadata(@ia_id)
    unless @metadata && @metadata[:imagecount]
      flash[:error] = I18n.t('tocs.flash.unable_to_fetch_metadata')
      redirect_to @toc and return
    end

    # Pagination parameters
    @page_size = 20 # Show 20 pages at a time
    @current_page = (params[:page] || 1).to_i
    @total_pages = (@metadata[:imagecount].to_f / @page_size).ceil

    # Calculate page range
    start_page = (@current_page - 1) * @page_size
    end_page = [start_page + @page_size - 1, @metadata[:imagecount] - 1].min

    # Get page images for current pagination window
    @pages = ol_client.ia_page_images(@ia_id, start_page: start_page, end_page: end_page)

    # Parse already marked pages if any
    @marked_pages = parse_marked_pages(@toc.toc_page_urls)
  end

  # POST /tocs/:id/mark_pages
  # Save the marked TOC pages
  def mark_pages
    marked_page_urls = params[:marked_pages] || []
    no_explicit_toc = params[:no_explicit_toc] == '1'

    # Validate: must have either marked pages OR no_explicit_toc
    if marked_page_urls.empty? && !no_explicit_toc
      flash[:error] = I18n.t('tocs.flash.mark_pages_required')
      redirect_to browse_scans_toc_path(@toc) and return
    end

    # Store marked pages as newline-separated URLs
    @toc.toc_page_urls = marked_page_urls.join("\n") unless marked_page_urls.empty?
    @toc.no_explicit_toc = no_explicit_toc
    @toc.status = :pages_marked

    if @toc.save
      flash[:notice] = I18n.t('tocs.flash.pages_marked_successfully')
      redirect_to @toc
    else
      flash[:error] = I18n.t('tocs.flash.failed_to_save_marked_pages')
      redirect_to browse_scans_toc_path(@toc)
    end
  end

  # POST /tocs/:id/mark_transcribed
  # Marks the TOC as transcribed and records the contributor
  def mark_transcribed
    unless @toc.pages_marked?
      flash[:error] = I18n.t('tocs.flash.must_be_pages_marked_to_transcribe')
      redirect_to @toc and return
    end

    @toc.contributor_id = current_user.id
    @manifestation = process_toc(@toc['toc_body'])
    @toc.manifestation = @manifestation
    @toc.status = :transcribed

    if @toc.save
      flash[:notice] = I18n.t('tocs.flash.marked_as_transcribed_successfully')
      redirect_to @toc
    else
      flash[:error] = I18n.t('tocs.flash.failed_to_mark_transcribed')
      redirect_to @toc
    end
  end

  # POST /tocs/:id/verify
  # Verifies the transcription and records the reviewer
  def verify
    unless @toc.transcribed?
      flash[:error] = I18n.t('tocs.flash.must_be_transcribed_to_verify')
      redirect_to @toc and return
    end

    # Prevent contributor from verifying their own ToC
    if @toc.contributor_id == current_user.id
      flash[:error] = I18n.t('tocs.flash.cannot_verify_own_toc')
      redirect_to @toc and return
    end

    @toc.reviewer_id = current_user.id
    @toc.status = :verified

    if @toc.save
      flash[:notice] = I18n.t('tocs.flash.verified_successfully')
      redirect_to @toc
    else
      flash[:error] = I18n.t('tocs.flash.failed_to_verify')
      redirect_to @toc
    end
  end

  # POST /tocs/create_multiple
  # Creates multiple TOC entries from selected publications
  def create_multiple
    book_ids = params[:book_ids] || []
    source = params[:source] || 'openlibrary'

    if book_ids.empty?
      flash[:error] = I18n.t('tocs.flash.no_books_selected')
      redirect_to publications_search_path and return
    end

    created_count = 0
    book_ids.each do |book_id|
      begin
        if source == 'gutendex'
          # Fetch book details from Gutendex
          gutendex_client = Gutendex::Client.new
          book_data = gutendex_client.book(book_id)
          book_uri = "https://www.gutenberg.org/ebooks/#{book_id}"

          # Create TOC with pages_marked status (since PG has texts, not scans)
          toc = Toc.new(
            book_uri: book_uri,
            title: book_data['title'] || "Book #{book_id}",
            status: :pages_marked,
            imported_subjects: extract_subjects_from_gutendex(book_data)
          )
        else
          # Fetch book details from OpenLibrary
          book_uri = "http://openlibrary.org/books/#{book_id}"
          book_data = rest_get("#{book_uri}.json")

          # Create TOC with empty status
          toc = Toc.new(
            book_uri: book_uri,
            title: book_data['title'] || "Book #{book_id}",
            status: :empty
          )
        end

        if toc.save
          created_count += 1
        end
      rescue => e
        logger.error "Failed to create TOC for #{book_id}: #{e.message}"
      end
    end

    if created_count > 0
      flash[:notice] = I18n.t('tocs.flash.created_multiple_success', count: created_count)
      redirect_to tocs_path(status: 'empty')
    else
      flash[:error] = I18n.t('tocs.flash.failed_to_create_any')
      redirect_to publications_search_path
    end
  end

  protected

  def new_from_openlibrary
    @toc.book_uri = "http://openlibrary.org/books/#{params[:ol_book_id]}"
    get_authors(@toc.book_uri)
    @toc.title = @book['title']
  end

  def new_from_gutendex
    pg_book_id = params[:pg_book_id]
    @toc.book_uri = "https://www.gutenberg.org/ebooks/#{pg_book_id}"

    # Fetch book details from Gutendex
    gutendex_client = Gutendex::Client.new
    book_data = gutendex_client.book(pg_book_id)

    @toc.title = book_data['title']
    @toc.imported_subjects = extract_subjects_from_gutendex(book_data)
    # Store book_data for later use (e.g., in edit action)
    @toc.book_data = book_data
    @toc.source = :gutenberg
    # Use generalized get_authors method with Gutendex book data
    get_authors(book_data)
  end

  def get_authors(uri_or_book_data)
    # Support both Open Library URI and Gutendex book data
    # Determine source: either from @toc.source or by checking if uri_or_book_data is a Hash (Gutendex) or String (OpenLibrary URI)
    is_gutenberg = @toc&.source == 'gutenberg' || (uri_or_book_data.is_a?(Hash) && !uri_or_book_data.key?('key'))

    if is_gutenberg
      # Gutendex book data passed directly (already deserialized as Hash from serialize :book_data)
      @book = uri_or_book_data.is_a?(String) ? JSON.parse(uri_or_book_data) : uri_or_book_data
      @authors = @book['authors'] || []
      # Transform Gutendex authors to ensure consistent format
      @authors = @authors.map do |author|
        {
          'name' => author['name'],
          'birth_year' => author['birth_year'],
          'death_year' => author['death_year']
        }
      end
    else
      # Open Library URI - wrap in error handling
      begin
        uri = uri_or_book_data
        @book = rest_get("#{uri}.json")
        author_keys = @book['authors'].collect { |b| b['key'] }
        @authors = author_keys.map { |k| rest_get("http://openlibrary.org#{k}.json") }
      rescue RestClient::Exception, SocketError, Errno::ECONNREFUSED, Timeout::Error, JSON::ParserError, StandardError => e
        # Log the error for debugging (safely handle exception message)
        begin
          logger.error "Failed to fetch author information from Open Library: #{e.class} - #{e.message}"
        rescue
          logger.error "Failed to fetch author information from Open Library: #{e.class}"
        end

        # Set authors to empty array so views don't break
        @book ||= {}
        @authors = []

        # Show warning to user (using flash.now for AJAX/edit requests)
        flash.now[:warning] = I18n.t('tocs.flash.openlibrary_server_error')

        # Return early - no need to call map_authors with empty data
        return
      end
    end
    map_authors
  end

  def store_authors
    return if @authors.blank? || @toc.nil? || @toc.new_record?

    # Clear existing authors to handle updates
    @toc.people_tocs.destroy_all

    # Create PeopleToc records for each author
    @authors.each do |author|
      person = author['person']
      next if person.nil?

      PeopleToc.create!(person: person, toc: @toc)
    end
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def process_toc(markdown)
    level = 1
    seqno = 1
    prev_work = []
    prev_expression = []
    aggregating_work = Work.new(title: @toc.title)
    aggregating_work.save!
    aggregating_expression = Expression.new(title: @toc.title)
    aggregating_expression.save!
    m = Manifestation.new(title: @toc.title) # TODO: likewise
    m.save!
    # important that the aggregating expression's embodiment is nil
    emb = Embodiment.new(expression_id: aggregating_expression.id, manifestation_id: m.id, sequence_number: nil)
    emb.save!
    markdown.lines.each do |line|
      # TODO: handle metadata lines
      next unless line.strip =~ /^#+/ # not expecting any other kind of line
      new_level = $&.length
      line_content = $'.strip
      next if line_content.end_with?('/') # Skip section headings

      # Parse title and authors from TOC line
      title, author_names = parse_toc_authors(line_content)

      # Create Work with clean title (no author string)
      w = Work.new(title: title) # TODO: add other details if specified in metadata
      w.save!

      # Create/find Person records and link to Work
      if author_names.any?
        # Explicit authors in TOC line
        persons = find_or_create_persons(author_names)
        link_authors_to_work(w, persons)
      elsif @toc.authors.present?
        # Fallback: use book's principal authors
        link_authors_to_work(w, @toc.authors)
      end

      e = Expression.new(title: title) # TODO: likewise
      e.save!
      w.expressions << e
      emb = Embodiment.new(expression_id: e.id, manifestation_id: m.id, sequence_number: seqno)
      emb.save!
      seqno += 1
      if new_level == 1 # then this work is top level, under the aggregating work
        add_components(aggregating_work, aggregating_expression, w, e) # aggregation
      elsif new_level == level + 1 # work at sub-level of previous work
        add_components(prev_work[level], prev_expression[level], w, e) # aggregation
      elsif new_level == level # further work at this level that isn't 1
        add_components(prev_work[level - 1], prev_expression[level - 1], w, e) # aggregation
        prev_work[level].insert_after(w) # sequence
        prev_expression[level].insert_after(e) # sequence
      elsif new_level == level - 1 # back to a previous level that isn't 1
        add_components(prev_work[level - 2], prev_expression[level - 2], w, e) # aggregation
        prev_work[new_level].insert_after(w) # sequence
        prev_expression[new_level].insert_after(e) # sequence
      end
      level = new_level
      prev_work[level] = w
      prev_expression[level] = e
    end
    m
  end

  def get_ocr_from_service(url)
    ocr_method = ENV.fetch('OCR_METHOD', 'tesseract')

    case ocr_method
    when 'tesseract'
      get_ocr_with_tesseract(url)
    when 'rest'
      get_ocr_with_rest_api(url)
    else
      logger.error "Unknown OCR method: #{ocr_method}"
      "Error: Unknown OCR method configured"
    end
  rescue => e
    logger.error "OCR failed for #{url}: #{e.message}"
    "Error: OCR processing failed - #{e.message}"
  end

  def get_ocr_with_tesseract(url)
    require 'open3'
    require 'tempfile'

    tesseract_path = ENV.fetch('TESSERACT_PATH', 'tesseract')
    language = ENV.fetch('OCR_LANGUAGE', 'eng')

    # Download image to temporary file
    response = HTTParty.get(url, timeout: 30)
    unless response.success?
      raise "Failed to download image from #{url}: #{response.code}"
    end

    # Create temporary files for input image and output text
    Tempfile.create(['ocr_image', '.jpg']) do |image_file|
      image_file.binmode
      image_file.write(response.body)
      image_file.flush

      Tempfile.create(['ocr_output', '']) do |output_file|
        output_base = output_file.path
        output_file.close

        # Run tesseract: tesseract image.jpg output -l eng
        cmd = [tesseract_path, image_file.path, output_base, '-l', language]
        stdout, stderr, status = Open3.capture3(*cmd)

        unless status.success?
          raise "Tesseract failed: #{stderr}"
        end

        # Tesseract writes to output_base.txt
        output_text_file = "#{output_base}.txt"
        if File.exist?(output_text_file)
          text = File.read(output_text_file)
          File.unlink(output_text_file)
          return text.strip
        else
          raise "Tesseract did not produce output file"
        end
      end
    end
  end

  def get_ocr_with_rest_api(url)
    ocr_service = ENV['OCR_SERVICE_URL']

    unless ocr_service
      raise "OCR_SERVICE_URL not configured"
    end

    # Send POST request to OCR service with the image URL
    response = HTTParty.post(
      "#{ocr_service}/ocr",
      body: { url: url }.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 60
    )

    unless response.success?
      raise "OCR service returned error: #{response.code} - #{response.body}"
    end

    # Parse response - assuming service returns JSON with 'text' field
    result = JSON.parse(response.body)
    result['text'] || result['result'] || response.body
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_toc
    @toc = Toc.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def toc_params
    params.require(:toc).permit(:book_uri, :toc_body, :contributor_id, :reviewer_id, :comments, :title, :book_data, :no_explicit_toc)
  end

  def valid?(url)
    uri = URI.parse(url)
    uri.scheme[0..3] == 'http' && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  def add_components(container_work, container_expression, component_work, component_expression)
    container_work.append_component(component_work)
    container_expression.append_component(component_expression)
  end

  # Parse stored toc_page_urls into array
  # Returns array of URLs, or empty array if nil/blank
  def parse_marked_pages(toc_page_urls)
    return [] if toc_page_urls.blank?
    toc_page_urls.split("\n").map(&:strip).reject(&:blank?)
  end

  # Apply sorting to TOCs collection based on params
  def apply_sorting(tocs)
    # Whitelist of allowed sort columns
    allowed_columns = %w[title status created_at contributor_id reviewer_id]
    sort_column = params[:sort].presence_in(allowed_columns)
    sort_direction = params[:direction] == 'desc' ? :desc : :asc

    if sort_column
      # Handle contributor/reviewer sorting with joins
      case sort_column
      when 'contributor_id'
        tocs.left_joins(:contributor).order("users.name #{sort_direction}")
      when 'reviewer_id'
        tocs.left_joins(:reviewer).order("users.name #{sort_direction}")
      else
        tocs.order(sort_column => sort_direction)
      end
    else
      # Default sorting: created_at desc if showing empty status, otherwise updated_at desc
      if params[:status] == 'empty'
        tocs.order(created_at: :desc)
      else
        tocs.order(updated_at: :desc)
      end
    end
  end

  # Extract subject headings from Gutendex book data
  # Returns newline-separated string of subjects, or nil if no subjects
  def extract_subjects_from_gutendex(book_data)
    return nil unless book_data && book_data['subjects']

    subjects = book_data['subjects']
    return nil if subjects.empty?

    subjects.join("\n")
  end

  # Parse author names from TOC line
  # Returns: [title_without_authors, [author_name1, author_name2, ...]]
  def parse_toc_authors(line)
    if line.include?('||')
      title, author_string = line.split('||', 2)
      author_names = author_string.split(';').map(&:strip).reject(&:empty?)
      [title.strip, author_names]
    else
      [line, []]
    end
  end

  # Find or create Person records for author names
  # Returns: [Person, Person, ...]
  def find_or_create_persons(author_names)
    author_names.map do |name|
      Person.find_by(name: name) || Person.create!(name: name)
    end
  end

  # Link Person records to Work as creators
  def link_authors_to_work(work, persons)
    persons.each do |person|
      PeopleWork.create!(person: person, work: work)
    end
  end
end

