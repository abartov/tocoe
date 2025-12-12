require 'rails_helper'

RSpec.describe "aboutnesses/index.html.haml", type: :view do
  let(:expression) { Expression.create!(title: "Test Expression") }
  let(:manifestation) { Manifestation.create!(title: "Test Manifestation") }
  let(:embodiment) { Embodiment.create!(expression: expression, manifestation: manifestation) }
  let(:aboutnesses) { [] }

  before do
    assign(:embodiment, embodiment)
    assign(:aboutnesses, aboutnesses)
  end

  it "renders the subject headings page" do
    render

    expect(rendered).to have_selector('h1', text: 'Subject Headings')
    expect(rendered).to have_link('Add Subject Heading', href: new_embodiment_aboutness_path(embodiment))
  end

  context "when the embodiment has no aboutnesses" do
    it "displays a message" do
      render

      expect(rendered).to have_content('No subject headings assigned yet.')
    end
  end

  context "when the embodiment's manifestation has a toc" do
    let(:toc) { Toc.create!(manifestation: manifestation, status: :empty) }

    before do
      toc # Ensure toc is created
    end

    it "displays a link back to the toc" do
      render

      expect(rendered).to have_link('Back to ToC', href: toc_path(toc))
    end
  end

  context "when the embodiment's manifestation has no toc" do
    it "does not display a link back to the toc" do
      render

      expect(rendered).not_to have_link('Back to ToC')
    end
  end

  describe 'displaying work authors' do
    context 'when the work has authors' do
      it 'displays the authors' do
        work = Work.create!(title: "Test Work")
        Reification.create!(work: work, expression: expression)
        author1 = Person.create!(name: "Jane Author")
        author2 = Person.create!(name: "John Writer")
        PeopleWork.create!(work: work, person: author1)
        PeopleWork.create!(work: work, person: author2)

        render

        expect(rendered).to have_content('Authors:')
        expect(rendered).to have_content('Jane Author, John Writer')
      end
    end

    context 'when the work has no authors' do
      it 'does not display the authors section' do
        work = Work.create!(title: "Test Work")
        Reification.create!(work: work, expression: expression)

        render

        expect(rendered).not_to have_content('Authors:')
      end
    end

    context 'when there is no work associated' do
      it 'does not raise an error' do
        expect { render }.not_to raise_error
      end
    end
  end

  describe 'displaying Toc-level authors' do
    let(:toc) { Toc.create!(manifestation: manifestation, status: :empty, title: 'Test TOC', book_uri: 'http://example.com/book') }

    context 'when the Toc has authors' do
      it 'displays the Toc-level authors' do
        toc # Ensure toc is created
        author1 = Person.create!(name: "TOC Author One")
        author2 = Person.create!(name: "TOC Author Two")
        PeopleToc.create!(toc: toc, person: author1)
        PeopleToc.create!(toc: toc, person: author2)

        render

        expect(rendered).to have_content('Authors:')
        expect(rendered).to have_content('from TOC')
        expect(rendered).to have_content('TOC Author One, TOC Author Two')
      end
    end

    context 'when the Toc has no authors' do
      it 'does not display the Toc authors section' do
        toc # Ensure toc is created

        render

        expect(rendered).not_to have_content('from TOC')
      end
    end

    context 'when there is no Toc associated' do
      it 'does not raise an error' do
        expect { render }.not_to raise_error
      end
    end
  end
end
