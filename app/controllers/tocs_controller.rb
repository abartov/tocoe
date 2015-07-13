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
  end

  # GET /tocs/new
  def new
    @toc = Toc.new
  end

  # GET /tocs/1/edit
  def edit
  end

  # POST /tocs
  # POST /tocs.json
  def create
    @toc = Toc.new(toc_params)

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
    ocr_images.each { |uri| 
      next unless uri =~ /\S/
      error = true unless valid?(uri)
    }
    if error
      @results = "<One or more invalid URLs above>"
    else
      @results = ''
      ocr_images.each { |url|
        next unless url =~ /\S/
        @results += get_ocr_from_service(url)+"\n\n"
      }
    end
  end

  private
    def get_ocr_from_service(url)
      res = ''
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_toc
      @toc = Toc.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def toc_params
      params.require(:toc).permit(:book_uri, :toc_body, :status, :contributor_id, :reviewer_id, :comments)
    end
   require 'uri'

   def valid?(url)
     uri = URI.parse(url)
     uri.kind_of?(URI::HTTP)
   rescue URI::InvalidURIError
     false
   end 
end