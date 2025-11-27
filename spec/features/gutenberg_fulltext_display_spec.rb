require 'rails_helper'

RSpec.feature 'Gutenberg fulltext in-page display', type: :feature do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:gutendex_client) { instance_double(Gutendex::Client) }
  let(:fulltext_url) { 'https://www.gutenberg.org/files/84/84-h/84-h.htm' }

  before do
    sign_in_as(user)
    allow(Gutendex::Client).to receive(:new).and_return(gutendex_client)
    allow(gutendex_client).to receive(:preferred_fulltext_url).with('84').and_return(fulltext_url)
  end

  scenario 'displays Gutenberg HTML fulltext in iframe for empty TOC' do
    # Create a Project Gutenberg TOC with empty status
    toc = Toc.create!(
      book_uri: 'https://www.gutenberg.org/ebooks/84',
      title: 'Frankenstein',
      status: :empty,
      book_data: {
        'title' => 'Frankenstein',
        'authors' => [{ 'name' => 'Shelley, Mary Wollstonecraft', 'birth_year' => 1797, 'death_year' => 1851 }]
      }
    )

    visit edit_toc_path(toc)

    # Should show the fulltext available message
    expect(page).to have_content('Full text available')

    # Should contain an iframe with the fulltext URL
    expect(page).to have_selector("iframe[src='#{fulltext_url}']")

    # Should show help text about scrolling through the text
    expect(page).to have_content('Scroll through the full text below')
  end

  scenario 'does not show iframe for non-Gutenberg books' do
    # Create an Open Library TOC
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Open Library Book',
      status: :empty
    )

    # Stub the rest_get call for Open Library
    allow_any_instance_of(ApplicationController).to receive(:rest_get).and_return(
      { 'title' => 'Open Library Book', 'authors' => [] }
    )

    visit edit_toc_path(toc)

    # Should not contain an iframe
    expect(page).not_to have_selector('iframe')

    # Should show the browse scans prompt instead
    expect(page).to have_content('No TOC pages marked yet')
    expect(page).to have_link('Browse Scans to Mark TOC Pages')
  end

  scenario 'does not show iframe when TOC has pages marked' do
    # Create a Gutenberg TOC with pages_marked status
    toc = Toc.create!(
      book_uri: 'https://www.gutenberg.org/ebooks/84',
      title: 'Frankenstein',
      status: :pages_marked,
      toc_page_urls: "https://archive.org/page1.jpg\nhttps://archive.org/page2.jpg",
      book_data: {
        'title' => 'Frankenstein',
        'authors' => [{ 'name' => 'Shelley, Mary Wollstonecraft', 'birth_year' => 1797, 'death_year' => 1851 }]
      }
    )

    visit edit_toc_path(toc)

    # Should not show the iframe (OCR section shows instead)
    expect(page).not_to have_selector("iframe[src='#{fulltext_url}']")

    # Should show OCR section
    expect(page).to have_content('Urls of toc page images', normalize_ws: true)
  end
end
