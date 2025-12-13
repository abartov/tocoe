require 'rails_helper'

RSpec.describe 'manifestations/_show.html.haml', type: :view do
  let(:manifestation) { Manifestation.create!(title: "Test Publication") }

  before do
    # Stub current_user for view specs (Devise/Warden not available in view specs)
    allow(view).to receive(:current_user).and_return(nil)
  end

  describe 'displaying publication authors' do
    context 'when the publication has authors' do
      it 'displays the authors' do
        # Create the FRBR structure: Work -> Expression -> Embodiment -> Manifestation
        work = Work.create!(title: "Test Publication")
        expression = Expression.create!(title: "Test Publication")
        Reification.create!(work: work, expression: expression)
        embodiment = Embodiment.create!(
          manifestation: manifestation,
          expression: expression,
          sequence_number: nil  # Main embodiment
        )

        # Add authors to the work
        author1 = Person.create!(name: "Jane Doe")
        author2 = Person.create!(name: "John Smith")
        PeopleWork.create!(work: work, person: author1)
        PeopleWork.create!(work: work, person: author2)

        render partial: 'manifestations/show', locals: { manifestation: manifestation }

        expect(rendered).to have_content('Authors:')
        expect(rendered).to have_content('Jane Doe, John Smith')
      end
    end

    context 'when the publication has no authors' do
      it 'does not display the authors section' do
        work = Work.create!(title: "Test Publication")
        expression = Expression.create!(title: "Test Publication")
        Reification.create!(work: work, expression: expression)
        Embodiment.create!(
          manifestation: manifestation,
          expression: expression,
          sequence_number: nil
        )

        render partial: 'manifestations/show', locals: { manifestation: manifestation }

        expect(rendered).not_to have_content('Authors:')
      end
    end

    context 'when there is no main embodiment' do
      it 'does not raise an error' do
        expect {
          render partial: 'manifestations/show', locals: { manifestation: manifestation }
        }.not_to raise_error
      end
    end
  end

  describe 'displaying individual work authors in TOC' do
    it 'displays authors for each work in the table of contents' do
      # Create main embodiment
      main_work = Work.create!(title: "Test Anthology")
      main_expression = Expression.create!(title: "Test Anthology")
      Reification.create!(work: main_work, expression: main_expression)
      Embodiment.create!(
        manifestation: manifestation,
        expression: main_expression,
        sequence_number: nil
      )

      # Create first component work with author
      work1 = Work.create!(title: "First Story")
      expression1 = Expression.create!(title: "First Story")
      Reification.create!(work: work1, expression: expression1)
      embodiment1 = Embodiment.create!(
        manifestation: manifestation,
        expression: expression1,
        sequence_number: 1
      )
      author1 = Person.create!(name: "Alice Author")
      PeopleWork.create!(work: work1, person: author1)

      # Create second component work with different author
      work2 = Work.create!(title: "Second Story")
      expression2 = Expression.create!(title: "Second Story")
      Reification.create!(work: work2, expression: expression2)
      embodiment2 = Embodiment.create!(
        manifestation: manifestation,
        expression: expression2,
        sequence_number: 2
      )
      author2 = Person.create!(name: "Bob Writer")
      PeopleWork.create!(work: work2, person: author2)

      render partial: 'manifestations/show', locals: { manifestation: manifestation }

      expect(rendered).to have_content('First Story')
      expect(rendered).to have_content('— Alice Author')
      expect(rendered).to have_content('Second Story')
      expect(rendered).to have_content('— Bob Writer')
    end

    it 'does not display author information when work has no authors' do
      # Create main embodiment
      main_work = Work.create!(title: "Test Anthology")
      main_expression = Expression.create!(title: "Test Anthology")
      Reification.create!(work: main_work, expression: main_expression)
      Embodiment.create!(
        manifestation: manifestation,
        expression: main_expression,
        sequence_number: nil
      )

      # Create component work without author
      work = Work.create!(title: "Anonymous Story")
      expression = Expression.create!(title: "Anonymous Story")
      Reification.create!(work: work, expression: expression)
      Embodiment.create!(
        manifestation: manifestation,
        expression: expression,
        sequence_number: 1
      )

      render partial: 'manifestations/show', locals: { manifestation: manifestation }

      expect(rendered).to have_content('Anonymous Story')
      expect(rendered).not_to match(/—.*Anonymous Story/)
    end
  end
end
