class PeopleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_person, only: [:show, :edit, :update]

  def index
    @people = Person.order(name: :asc)
  end

  def show
  end

  def new
    @person = Person.new
  end

  def create
    @person = Person.new(person_params)

    if @person.save
      redirect_to @person, notice: I18n.t('people.flash.created_successfully')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @person.update(person_params)
      redirect_to @person, notice: I18n.t('people.flash.updated_successfully')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # AJAX endpoint for searching VIAF by person name
  def search_viaf
    query = params[:query]
    client = Viaf::Client.new
    results = client.search_person(query)
    render json: results
  end

  # AJAX endpoint for searching Wikidata by person name
  def search_wikidata
    query = params[:query]
    client = SubjectHeadings::WikidataClient.new
    raw_results = client.search(query, count: 20)

    # Transform results: extract Q number from URI
    results = raw_results.map do |r|
      q_number = r[:uri].split('/').last.gsub('Q', '').to_i
      { wikidata_q: q_number, label: r[:label] }
    end

    render json: results
  end

  # AJAX endpoint for searching Library of Congress Name Authority by person name
  def search_loc
    query = params[:query]
    client = LibraryOfCongress::NameAuthorityClient.new
    results = client.search_person(query)
    render json: results
  end

  # AJAX endpoint for searching all authority sources at once
  # POST /people/search_all
  # Params: { query: string, candidates: [{ source: string, id: string, label: string }] }
  def search_all
    query = params[:query]
    candidates = params[:candidates] || []

    results = PersonMatcherService.search_all(query: query, candidates: candidates)
    render json: results
  end

  # AJAX endpoint for fetching detailed information about a person
  # GET /people/fetch_details?source=viaf&id=113230702
  def fetch_details
    source = params[:source]
    id = params[:id]

    details = PersonMatcherService.fetch_details(source: source, id: id)

    if details
      render json: details
    else
      render json: { error: 'Details not found' }, status: :not_found
    end
  end

  # AJAX endpoint for matching a person to a target object
  # POST /people/match
  # Params: { target_type: string, target_id: integer, source: string, external_id: string, person_id: integer|null }
  def match
    result = PersonMatcherService.match(
      target_type: params[:target_type],
      target_id: params[:target_id],
      source: params[:source],
      external_id: params[:external_id],
      person_id: params[:person_id]
    )

    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end

  # AJAX endpoint for accepting a parent (TOC-level) match for a work
  # POST /people/accept_parent_match
  # Params: { work_id: integer, person_id: integer, role: string }
  def accept_parent_match
    work_id = params[:work_id]
    person_id = params[:person_id]
    role = params[:role] || 'author'

    # Validate inputs
    unless work_id.present? && person_id.present?
      render json: { success: false, error: 'Missing required parameters' }, status: :bad_request
      return
    end

    # Find the work and person
    work = Work.find_by(id: work_id)
    person = Person.find_by(id: person_id)

    unless work && person
      render json: { success: false, error: 'Work or Person not found' }, status: :not_found
      return
    end

    # Create association based on role
    success = case role.to_s
              when 'translator'
                # Associate with expression as a realizer
                expression = work.expressions.first
                if expression
                  Realization.find_or_create_by(realizer: person, expression: expression)
                  true
                else
                  false
                end
              else # 'author' or default
                # Associate with work as a creator
                PeopleWork.find_or_create_by(person: person, work: work)
                true
              end

    if success
      render json: { success: true, person: { id: person.id, name: person.name } }
    else
      render json: { success: false, error: 'Failed to create association' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error accepting parent match: #{e.message}"
    render json: { success: false, error: e.message }, status: :internal_server_error
  end

  # AJAX endpoint for undoing a match between work/expression and person
  # POST /people/undo_match
  # Params: { work_id: integer, person_id: integer, role: string }
  def undo_match
    work_id = params[:work_id]
    person_id = params[:person_id]
    role = params[:role] || 'author'

    # Validate inputs
    unless work_id.present? && person_id.present?
      render json: { success: false, error: 'Missing required parameters' }, status: :bad_request
      return
    end

    # Find the work and person
    work = Work.find_by(id: work_id)
    person = Person.find_by(id: person_id)

    unless work && person
      render json: { success: false, error: 'Work or Person not found' }, status: :not_found
      return
    end

    # Remove association based on role
    success = case role.to_s
              when 'translator'
                # Remove association with expression as a realizer
                expression = work.expressions.first
                if expression
                  realization = Realization.find_by(realizer: person, expression: expression)
                  realization&.destroy
                  true
                else
                  false
                end
              else # 'author' or default
                # Remove association with work as a creator
                people_work = PeopleWork.find_by(person: person, work: work)
                people_work&.destroy
                true
              end

    if success
      render json: { success: true, person: { id: person.id, name: person.name } }
    else
      render json: { success: false, error: 'Failed to remove association' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error undoing match: #{e.message}"
    render json: { success: false, error: e.message }, status: :internal_server_error
  end

  private

  def set_person
    @person = Person.find(params[:id])
  end

  def person_params
    params.require(:person).permit(
      :name,
      :dates,
      :title,
      :affiliation,
      :country,
      :comment,
      :viaf_id,
      :wikidata_q,
      :openlibrary_id,
      :loc_id,
      :gutenberg_id
    )
  end
end
