class AboutnessesController < ApplicationController
  before_action :set_embodiment, only: [:index, :new, :create, :search]

  # GET /embodiments/:embodiment_id/aboutnesses
  # List all aboutnesses for an embodiment
  def index
    @aboutnesses = @embodiment.aboutnesses
  end

  # GET /embodiments/:embodiment_id/aboutnesses/new
  # Show form to select source and search for subject headings
  def new
    @aboutness = Aboutness.new
  end

  # POST /embodiments/:embodiment_id/aboutnesses/search
  # AJAX endpoint to search for subject headings
  def search
    source = params[:source]
    query = params[:query]

    @results = case source
               when 'LCSH'
                 SubjectHeadings::LcshClient.new.search(query)
               when 'Wikidata'
                 SubjectHeadings::WikidataClient.new.search(query)
               else
                 []
               end

    respond_to do |format|
      format.json { render json: @results }
    end
  end

  # POST /embodiments/:embodiment_id/aboutnesses
  # Create a new aboutness for the embodiment
  def create
    @aboutness = @embodiment.aboutnesses.new(aboutness_params)

    if @aboutness.save
      redirect_to embodiment_aboutnesses_path(@embodiment), notice: 'Subject heading was successfully added.'
    else
      render :new
    end
  end

  # DELETE /aboutnesses/:id
  # Remove an aboutness
  def destroy
    @aboutness = Aboutness.find(params[:id])
    embodiment = @aboutness.embodiment
    @aboutness.destroy

    redirect_to embodiment_aboutnesses_path(embodiment), notice: 'Subject heading was successfully removed.'
  end

  private

  def set_embodiment
    @embodiment = Embodiment.find(params[:embodiment_id])
  end

  def aboutness_params
    params.require(:aboutness).permit(:subject_heading_uri, :source_name, :subject_heading_label)
  end
end
