require 'rails_helper'

RSpec.feature 'Bulk create TOCs', type: :feature, js: true do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    # Sign in the user for this feature test
    sign_in_as(user)

    # Stub OpenLibrary search to return two mock books
    docs = [
      { 'editions' => { 'docs' => [{ 'key' => '/books/OL1M' }] }, 'title' => 'First Book', 'author_name' => ['Author One'], 'has_fulltext' => true, 'ebook_access' => 'public' },
      { 'editions' => { 'docs' => [{ 'key' => '/books/OL2M' }] }, 'title' => 'Second Book', 'author_name' => ['Author Two'], 'has_fulltext' => true, 'ebook_access' => 'public' }
    ]

    allow_any_instance_of(OpenLibrary::Client).to receive(:search).and_return({ 'numFound' => 2, 'docs' => docs })

    # Stub rest_get so create_multiple doesn't perform real HTTP calls
    allow_any_instance_of(ApplicationController).to receive(:rest_get) do |_, url|
      # Return appropriate title based on the book ID in the URL
      if url.include?('OL1M')
        { 'title' => 'First Book' }
      elsif url.include?('OL2M')
        { 'title' => 'Second Book' }
      else
        { 'title' => "Title for #{url}" }
      end
    end
  end

  scenario 'selecting books and creating TOCs submits inner form' do
    # Visit the search page with a query so @results are populated
    visit '/publications/search?search=test'

    # Activate multi-select mode
    find('#toggle-multiselect').click

    # Check both book checkboxes
    find("input.book-checkbox[value='OL1M']", visible: true).set(true)
    find("input.book-checkbox[value='OL2M']", visible: true).set(true)

    # Click the bulk create button
    find('#bulk-create-btn', visible: true).click

    # Expect to be redirected to the TOCs index with the created TOCs visible
    expect(page.current_path).to eq('/tocs')
    expect(page).to have_content('First Book')
    expect(page).to have_content('Second Book')
  end
end
