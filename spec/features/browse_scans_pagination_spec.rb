require 'rails_helper'

RSpec.feature 'Browse Scans Pagination', type: :feature do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:toc) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL123M', title: 'Test Book') }
  let(:ol_client) { instance_double(OpenLibrary::Client) }
  let(:ia_metadata) { { imagecount: 100, title: 'Test Book', page_progression: 'lr' } }

  before do
    sign_in_as(user)
    allow(OpenLibrary::Client).to receive(:new).and_return(ol_client)
    allow(ol_client).to receive(:ia_identifier).with('OL123M').and_return('test_ia_id')
    allow(ol_client).to receive(:ia_metadata).with('test_ia_id').and_return(ia_metadata)
  end

  context 'when viewing first page' do
    before do
      page_images = (0...20).map do |n|
        {
          page_number: n,
          url: "https://archive.org/download/test_id/page/n#{n}.jpg",
          thumb_url: "https://archive.org/download/test_id/page/n#{n}.jpg?scale=8"
        }
      end
      allow(ol_client).to receive(:ia_page_images).and_return(page_images)
    end

    scenario 'displays Last button as enabled' do
      visit browse_scans_toc_path(toc)

      expect(page).to have_link('Last', href: browse_scans_toc_path(toc, page: 5))
    end

    scenario 'Last button navigates to last page' do
      visit browse_scans_toc_path(toc)

      click_link 'Last'

      expect(page).to have_current_path(browse_scans_toc_path(toc, page: 5))
    end
  end

  context 'when viewing middle page' do
    before do
      page_images = (40...60).map do |n|
        {
          page_number: n,
          url: "https://archive.org/download/test_id/page/n#{n}.jpg",
          thumb_url: "https://archive.org/download/test_id/page/n#{n}.jpg?scale=8"
        }
      end
      allow(ol_client).to receive(:ia_page_images).and_return(page_images)
    end

    scenario 'displays Last button as enabled' do
      visit browse_scans_toc_path(toc, page: 3)

      expect(page).to have_link('Last', href: browse_scans_toc_path(toc, page: 5))
    end

    scenario 'Last button navigates to last page' do
      visit browse_scans_toc_path(toc, page: 3)

      click_link 'Last'

      expect(page).to have_current_path(browse_scans_toc_path(toc, page: 5))
    end
  end

  context 'when viewing last page' do
    before do
      page_images = (80...100).map do |n|
        {
          page_number: n,
          url: "https://archive.org/download/test_id/page/n#{n}.jpg",
          thumb_url: "https://archive.org/download/test_id/page/n#{n}.jpg?scale=8"
        }
      end
      allow(ol_client).to receive(:ia_page_images).and_return(page_images)
    end

    scenario 'displays Last button as disabled' do
      visit browse_scans_toc_path(toc, page: 5)

      # Check for disabled state in pagination
      within('.pagination') do
        expect(page).to have_css('.page-item.disabled', text: 'Last')
        expect(page).not_to have_link('Last')
      end
    end
  end
end
