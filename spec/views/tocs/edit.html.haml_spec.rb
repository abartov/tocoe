require 'rails_helper'

RSpec.describe "tocs/edit.html.haml", type: :view do
  let(:user) { User.create!(email: 'test@example.com', password: 'password') }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'with imported subjects' do
    let(:toc) do
      Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/1342',
        title: 'Pride and Prejudice',
        imported_subjects: "Fiction\nRomance\nEngland -- Social life and customs"
      )
    end

    before do
      assign(:toc, toc)
      assign(:authors, [])
      render
    end

    it 'displays imported subjects' do
      expect(rendered).to have_selector('textarea#imported_subjects')
      expect(rendered).to have_content('Fiction')
    end

    it 'displays auto-match button for persisted toc with imported subjects' do
      expect(rendered).to have_selector('button#auto_match_subjects')
    end
  end

  context 'without imported subjects' do
    let(:toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book'
      )
    end

    before do
      assign(:toc, toc)
      assign(:authors, [])
      render
    end

    it 'does not display auto-match button when no imported subjects' do
      expect(rendered).not_to have_selector('button#auto_match_subjects')
    end
  end
end
