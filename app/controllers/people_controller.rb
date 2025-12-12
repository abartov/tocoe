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
