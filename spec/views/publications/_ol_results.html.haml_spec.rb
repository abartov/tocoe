require 'rails_helper'

RSpec.describe "publications/_ol_results", type: :view do
  before do
    assign(:source, 'openlibrary')
    assign(:any_fulltext, true)
  end

  context "with OpenLibrary results" do
    let(:results) do
      [
        {
          'title' => 'Test Book',
          'author_name' => ['Test Author'],
          'has_fulltext' => true,
          'ebook_access' => 'public',
          'key' => '/works/OL123W',
          'editions' => {
            'docs' => [
              { 'key' => '/books/OL123M' }
            ]
          }
        },
        {
          'title' => 'Restricted Book',
          'author_name' => ['Another Author'],
          'has_fulltext' => true,
          'ebook_access' => 'restricted',
          'key' => '/works/OL456W',
          'editions' => {
            'docs' => [
              { 'key' => '/books/OL456M' }
            ]
          }
        },
        {
          'title' => 'Metadata Only Book',
          'author_name' => ['Third Author'],
          'has_fulltext' => false,
          'key' => '/works/OL789W',
          'editions' => {
            'docs' => [
              { 'key' => '/books/OL789M' }
            ]
          }
        }
      ]
    end

    before do
      assign(:results, results)
    end

    it "renders book cards" do
      render
      expect(rendered).to have_selector('.book-card', count: 3)
    end

    it "displays book titles" do
      render
      expect(rendered).to have_content('Test Book')
      expect(rendered).to have_content('Restricted Book')
      expect(rendered).to have_content('Metadata Only Book')
    end

    it "displays authors" do
      render
      expect(rendered).to have_content('Test Author')
      expect(rendered).to have_content('Another Author')
      expect(rendered).to have_content('Third Author')
    end

    it "displays edition keys" do
      render
      expect(rendered).to have_content('OL123M')
      expect(rendered).to have_content('OL456M')
      expect(rendered).to have_content('OL789M')
    end

    it "shows fulltext status badges" do
      render
      expect(rendered).to have_selector('.label.label-success', text: I18n.t('publications.search.fulltext_labels.public'))
      expect(rendered).to have_selector('.label.label-warning', text: I18n.t('publications.search.fulltext_labels.restricted'))
      expect(rendered).to have_selector('.label.label-default', text: I18n.t('publications.search.fulltext_labels.metadata_only'))
    end

    it "shows Make ToC button for public fulltext books" do
      render
      expect(rendered).to have_link(I18n.t('publications.search.make_toc_button'), href: /ol_book_id=OL123M/)
    end

    it "shows restricted/no fulltext message for non-public books" do
      render
      expect(rendered).to have_content(I18n.t('publications.search.no_fulltext'))
    end

    it "includes checkboxes for books with public fulltext" do
      render
      expect(rendered).to have_selector('input[type="checkbox"].book-checkbox[value="OL123M"]')
    end

    it "does not include checkboxes for restricted/metadata-only books" do
      render
      expect(rendered).not_to have_selector('input[type="checkbox"].book-checkbox[value="OL456M"]')
      expect(rendered).not_to have_selector('input[type="checkbox"].book-checkbox[value="OL789M"]')
    end

    it "renders multi-select controls" do
      render
      expect(rendered).to have_selector('#multi-select-controls')
      expect(rendered).to have_selector('#bulk-toc-form')
      expect(rendered).to have_selector('#selection-count')
      expect(rendered).to have_selector('#bulk-create-btn.hidden-initially')
    end

    it "uses card grid layout" do
      render
      expect(rendered).to have_selector('.search-results-grid')
    end
  end

  context "with Gutendex (Project Gutenberg) results" do
    let(:results) do
      [
        {
          'id' => 12345,
          'title' => 'Pride and Prejudice',
          'author_name' => ['Jane Austen'],
          'source' => 'gutendex'
        },
        {
          'id' => 67890,
          'title' => 'Moby Dick',
          'author_name' => ['Herman Melville'],
          'source' => 'gutendex'
        }
      ]
    end

    before do
      assign(:results, results)
      assign(:source, 'gutendex')
    end

    it "renders book cards" do
      render
      expect(rendered).to have_selector('.book-card', count: 2)
    end

    it "displays Gutenberg IDs with PG prefix" do
      render
      expect(rendered).to have_content('PG-12345')
      expect(rendered).to have_content('PG-67890')
    end

    it "shows public fulltext badge for all Gutendex results" do
      render
      expect(rendered).to have_selector('.label.label-success', count: 2)
    end

    it "includes Make ToC button for all Gutendex results" do
      render
      expect(rendered).to have_link(I18n.t('publications.search.make_toc_button'), href: /pg_book_id=12345/)
      expect(rendered).to have_link(I18n.t('publications.search.make_toc_button'), href: /pg_book_id=67890/)
    end

    it "includes checkboxes for all Gutendex results" do
      render
      expect(rendered).to have_selector('input[type="checkbox"].book-checkbox[value="12345"]')
      expect(rendered).to have_selector('input[type="checkbox"].book-checkbox[value="67890"]')
    end
  end

  context "with no results" do
    before do
      assign(:results, [])
    end

    it "does not render book cards" do
      render
      expect(rendered).not_to have_selector('.book-card')
    end

    it "does not render multi-select controls" do
      render
      expect(rendered).not_to have_selector('#multi-select-controls')
    end

    context "when search was performed" do
      before do
        allow(view).to receive(:params).and_return({ search: 'test query' })
      end

      it "shows nothing found message" do
        render
        expect(rendered).to have_selector('.search-results-empty')
        expect(rendered).to have_content(I18n.t('publications.search.nothing_found'))
      end

      it "shows empty icon" do
        render
        expect(rendered).to have_selector('.empty-icon')
      end
    end
  end

  context "with mixed results (OpenLibrary and Gutendex)" do
    let(:results) do
      [
        {
          'title' => 'OL Book',
          'author_name' => ['OL Author'],
          'has_fulltext' => true,
          'ebook_access' => 'public',
          'key' => '/works/OL111W',
          'editions' => {
            'docs' => [
              { 'key' => '/books/OL111M' }
            ]
          }
        },
        {
          'id' => 99999,
          'title' => 'PG Book',
          'author_name' => ['PG Author'],
          'source' => 'gutendex'
        }
      ]
    end

    before do
      assign(:results, results)
    end

    it "renders all book cards" do
      render
      expect(rendered).to have_selector('.book-card', count: 2)
    end

    it "displays both types of books correctly" do
      render
      expect(rendered).to have_content('OL Book')
      expect(rendered).to have_content('PG Book')
      expect(rendered).to have_content('OL111M')
      expect(rendered).to have_content('PG-99999')
    end
  end

  context "with book missing edition data" do
    let(:results) do
      [
        {
          'title' => 'Book Without Edition',
          'author_name' => ['No Edition Author'],
          'has_fulltext' => true,
          'ebook_access' => 'public',
          'key' => '/works/OL999W',
          'editions' => {
            'docs' => []
          }
        }
      ]
    end

    before do
      assign(:results, results)
    end

    it "shows no edition message" do
      render
      expect(rendered).to have_content(I18n.t('publications.search.no_edition'))
    end

    it "does not show Make ToC button" do
      render
      expect(rendered).not_to have_link(I18n.t('publications.search.make_toc_button'))
    end
  end
end
