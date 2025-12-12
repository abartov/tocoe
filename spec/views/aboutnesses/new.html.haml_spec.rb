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
end
