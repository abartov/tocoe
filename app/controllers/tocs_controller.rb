require 'uri'
require 'httparty'
require 'rest-client'

# Tables of Contents controller
# rubocop:disable ClassLength
class TocsController < ApplicationController
  before_action :set_toc, only: [:show, :edit, :update, :destroy]

  # GET /tocs
  # GET /tocs.json
  def index
    @tocs = Toc.all
  end

  # GET /tocs/1
  # GET /tocs/1.json
  def show
    # @toc = Toc.find(params[:id])
    @manifestation = @toc.manifestation
  end

  # GET /tocs/new
  def new
    @toc = Toc.new
    case params[:from]
    when 'openlibrary'
      new_from_openlibrary
    end
  end

  def map_authors
    @authors.each_index do |i|
      p = Person.find_by_openlibrary_id(@authors[i]['key'])
      if p.nil?
        # create a new Person and link to Open Library ID
        p = Person.new(openlibrary_id: @authors[i]['key'], name: @authors[i]['name'])
        p.save!
      end
      @authors[i]['person'] = p
    end
  end

  # GET /tocs/1/edit
  def edit
    get_authors(@toc.book_uri)
  end

  # POST /tocs
  # POST /tocs.json
  def create
    @toc = Toc.new(toc_params)
    @manifestation = process_toc(@toc['toc_body'])
    @toc.manifestation = @manifestation
    respond_to do |format|
      if @toc.save
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
    @toc.destroy
    respond_to do |format|
      format.html { redirect_to tocs_url, notice: 'Toc was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # called via AJAX from tocs#new and tocs#edit
  def do_ocr
    error = false
    ocr_images = params[:ocr_images].split
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

  protected

  def new_from_openlibrary
    @toc.book_uri = "http://openlibrary.org/books/#{params[:ol_book_id]}"
    get_authors(@toc.book_uri)
    @toc.title = @book['title']
  end

  def get_authors(uri)
    @book = rest_get("#{uri}.json")
    author_keys = @book['authors'].collect { |b| b['key'] }
    @authors = author_keys.map { |k| rest_get("http://openlibrary.org#{k}.json") }
    map_authors
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
      title = $'.strip
      w = Work.new(title: title) # TODO: add other details if specified in metadata
      w.save!
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
    ocr_method = Rails.configuration.constants['OCR_method'] || 'tesseract'

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

    tesseract_path = Rails.configuration.constants['tesseract_path'] || 'tesseract'
    language = Rails.configuration.constants['OCR_language'] || 'eng'

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
    ocr_service = Rails.configuration.constants['OCR_service']

    unless ocr_service
      raise "OCR_service not configured"
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
    params.require(:toc).permit(:book_uri, :toc_body, :status, :contributor_id, :reviewer_id, :comments, :title)
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
end

