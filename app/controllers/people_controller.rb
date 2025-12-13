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
