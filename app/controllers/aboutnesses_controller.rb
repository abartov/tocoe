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
      # If remove_subject parameter is provided, remove it from the TOC's imported_subjects
      if params[:remove_subject].present?
        # Find the TOC associated with this embodiment
        toc = Toc.find_by(manifestation_id: @embodiment.manifestation_id)
        if toc && toc.imported_subjects.present?
          subjects = toc.imported_subjects.split("\n").map(&:strip).reject(&:blank?)
          subjects.delete(params[:remove_subject])
          toc.imported_subjects = subjects.join("\n")
          toc.save
        end
      end

      respond_to do |format|
        format.html { redirect_to embodiment_aboutnesses_path(@embodiment), notice: 'Subject heading was successfully added.' }
        format.json { render json: { success: true, aboutness: @aboutness }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { success: false, errors: @aboutness.errors.full_messages }, status: :unprocessable_entity }
      end
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
