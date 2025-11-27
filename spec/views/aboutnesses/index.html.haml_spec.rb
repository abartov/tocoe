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
end
