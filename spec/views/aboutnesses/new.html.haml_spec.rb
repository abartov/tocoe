require 'rails_helper'

RSpec.describe "aboutnesses/new.html.haml", type: :view do
  let(:embodiment) { Embodiment.create!(
    expression: Expression.create!(title: "Test Expression"),
    manifestation: Manifestation.create!(title: "Test Manifestation")
  ) }
  let(:aboutness) { Aboutness.new(embodiment: embodiment) }

  before do
    assign(:embodiment, embodiment)
    assign(:aboutness, aboutness)
  end

  it "renders the search form" do
    render

    expect(rendered).to have_selector('h1', text: 'Add Subject Heading')
    expect(rendered).to have_selector('#source_select')
    expect(rendered).to have_selector('#search_query')
    expect(rendered).to have_selector('#search_button')
  end

  it "includes JavaScript that renders search result URIs as clickable links opening in new tab" do
    render

    # Verify the JavaScript includes the link with target="_blank"
    expect(rendered).to include('<a href="\' + result.uri + \'" target="_blank">\' + result.uri + \'</a>')
  end

  it "renders the hidden form for submitting selected aboutness" do
    render

    expect(rendered).to have_selector('#aboutness_form', visible: :hidden)
    expect(rendered).to have_selector('#selected_uri', visible: :hidden)
    expect(rendered).to have_selector('#selected_source', visible: :hidden)
    expect(rendered).to have_selector('#selected_label', visible: :hidden)
  end

  context "when manifestation has a TOC" do
    let(:toc) { Toc.create!(title: "Test Publication", manifestation: embodiment.manifestation) }

    before do
      # Associate the TOC with the manifestation
      toc
      embodiment.manifestation.reload
    end

    it "displays the publication label and link" do
      render

      expect(rendered).to have_content(I18n.t('aboutnesses.new.publication_label'))
      expect(rendered).to have_link("Test Publication", href: toc_path(toc))
    end
  end

  context "when manifestation has no TOC" do
    it "does not display the publication section" do
      render

      expect(rendered).not_to have_content(I18n.t('aboutnesses.new.publication_label'))
    end
  end

  describe 'displaying work authors' do
    context 'when the work has authors' do
      it 'displays the authors' do
        work = Work.create!(title: "Test Work")
        Reification.create!(work: work, expression: embodiment.expression)
        author1 = Person.create!(name: "Author One")
        author2 = Person.create!(name: "Author Two")
        PeopleWork.create!(work: work, person: author1)
        PeopleWork.create!(work: work, person: author2)

        render

        expect(rendered).to have_content('Authors:')
        expect(rendered).to have_content('Author One, Author Two')
      end
    end

    context 'when the work has no authors' do
      it 'does not display the authors section' do
        work = Work.create!(title: "Test Work")
        Reification.create!(work: work, expression: embodiment.expression)

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
    let(:toc) { Toc.create!(title: "Test Publication", manifestation: embodiment.manifestation, book_uri: 'http://example.com/book') }

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
