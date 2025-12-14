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
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i

    # Calculate offset from page number (1-based to 0-based)
    offset = (page - 1) * per_page

    response = case source
               when 'LCSH'
                 SubjectHeadings::LcshClient.new.search(query, count: per_page, offset: offset)
               when 'Wikidata'
                 SubjectHeadings::WikidataClient.new.search(query, count: per_page, offset: offset)
               else
                 { results: [], has_more: false }
               end

    respond_to do |format|
      format.json do
        render json: {
          results: response[:results],
          has_more: response[:has_more],
          page: page,
          per_page: per_page
        }
      end
    end
  end

  # POST /embodiments/:embodiment_id/aboutnesses
  # Create a new aboutness for the embodiment
  def create
    @aboutness = @embodiment.aboutnesses.new(aboutness_params)

    # Set contributor and status for user-contributed aboutnesses
    # Imported aboutnesses should be created with contributor_id: nil and status: 'verified'
    if current_user && !params[:aboutness][:imported]
      @aboutness.contributor_id = current_user.id
      @aboutness.status = 'proposed'
    end

    if @aboutness.save
      # Auto-import related subject headings based on source
      case @aboutness.source_name
      when 'Wikidata'
        # If this is a Wikidata aboutness, check for Library of Congress Authority (P244)
        auto_add_library_of_congress_heading(@aboutness)
      when 'LCSH'
        # If this is an LCSH aboutness, check for Wikidata entity with matching P244
        auto_add_wikidata_heading(@aboutness)
      end

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

  # PATCH /aboutnesses/:id/verify
  # Verify an aboutness (only for aboutnesses not contributed by current user)
  def verify
    @aboutness = Aboutness.find(params[:id])
    embodiment = @aboutness.embodiment

    unless @aboutness.verifiable_by?(current_user)
      redirect_to embodiment_aboutnesses_path(embodiment), alert: 'You cannot verify this subject heading.'
      return
    end

    @aboutness.reviewer_id = current_user.id
    @aboutness.status = 'verified'

    if @aboutness.save
      redirect_to embodiment_aboutnesses_path(embodiment), notice: 'Subject heading was successfully verified.'
    else
      redirect_to embodiment_aboutnesses_path(embodiment), alert: 'Failed to verify subject heading.'
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

  # Automatically add Library of Congress subject heading if the Wikidata entity has P244
  def auto_add_library_of_congress_heading(wikidata_aboutness)
    # Extract entity ID from Wikidata URI (e.g., "Q395" from "http://www.wikidata.org/entity/Q395")
    entity_id = wikidata_aboutness.subject_heading_uri.split('/').last
    return unless entity_id.present? && entity_id.match?(/^Q\d+$/)

    # Fetch P244 (Library of Congress Authority) from Wikidata
    wikidata_client = SubjectHeadings::WikidataClient.new
    lc_id = wikidata_client.get_library_of_congress_id(entity_id)
    return unless lc_id.present?

    # Create LC aboutness with the same status as the Wikidata aboutness
    # Use https (not http) for LC URIs
    lc_uri = "https://id.loc.gov/authorities/subjects/#{lc_id}"

    # Check if this LC heading already exists for this embodiment
    existing = @embodiment.aboutnesses.find_by(subject_heading_uri: lc_uri)
    return if existing.present?

    # Create the LC aboutness with the same contributor/status as the Wikidata one
    lc_aboutness = @embodiment.aboutnesses.new(
      subject_heading_uri: lc_uri,
      source_name: 'LCSH',
      subject_heading_label: wikidata_aboutness.subject_heading_label, # Use same label
      contributor_id: wikidata_aboutness.contributor_id,
      status: wikidata_aboutness.status
    )

    if lc_aboutness.save
      Rails.logger.info("Auto-added LC subject heading #{lc_uri} from Wikidata entity #{entity_id}")
    else
      Rails.logger.error("Failed to auto-add LC subject heading: #{lc_aboutness.errors.full_messages.join(', ')}")
    end
  rescue StandardError => e
    Rails.logger.error("Error auto-adding LC subject heading: #{e.message}")
  end

  # Automatically add Wikidata subject heading if there's a matching P244
  def auto_add_wikidata_heading(lcsh_aboutness)
    # Extract LC authority ID from URI (e.g., "sh85082139" from "https://id.loc.gov/authorities/subjects/sh85082139")
    lc_id = lcsh_aboutness.subject_heading_uri.split('/').last
    return unless lc_id.present? && lc_id.match?(/^sh\d+$/)

    # Find Wikidata entity with this P244 value
    wikidata_client = SubjectHeadings::WikidataClient.new
    result = wikidata_client.find_entity_by_library_of_congress_id(lc_id)
    return unless result.present?

    entity_id = result[:entity_id]
    label = result[:label]

    # Create Wikidata aboutness with the same status as the LCSH aboutness
    wikidata_uri = "http://www.wikidata.org/entity/#{entity_id}"

    # Check if this Wikidata heading already exists for this embodiment
    existing = @embodiment.aboutnesses.find_by(subject_heading_uri: wikidata_uri)
    return if existing.present?

    # Create the Wikidata aboutness with the same contributor/status as the LCSH one
    wikidata_aboutness = @embodiment.aboutnesses.new(
      subject_heading_uri: wikidata_uri,
      source_name: 'Wikidata',
      subject_heading_label: label,
      contributor_id: lcsh_aboutness.contributor_id,
      status: lcsh_aboutness.status
    )

    if wikidata_aboutness.save
      Rails.logger.info("Auto-added Wikidata entity #{wikidata_uri} from LC authority #{lc_id}")
    else
      Rails.logger.error("Failed to auto-add Wikidata heading: #{wikidata_aboutness.errors.full_messages.join(', ')}")
    end
  rescue StandardError => e
    Rails.logger.error("Error auto-adding Wikidata heading: #{e.message}")
  end
end
