require 'rails_helper'

RSpec.describe "tocs/index.html.haml", type: :view do
  let(:contributor) { User.create!(email: 'contributor@example.com', password: 'password', name: 'John Contributor') }
  let(:reviewer) { User.create!(email: 'reviewer@example.com', password: 'password', name: 'Jane Reviewer') }
  let(:admin_user) { User.create!(email: 'admin@example.com', password: 'password', name: 'Admin User', admin: true) }
  let(:regular_user) { User.create!(email: 'user@example.com', password: 'password', name: 'Regular User', admin: false) }

  let(:toc1) do
    Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Book 1',
      status: :empty,
      contributor_id: contributor.id,
      reviewer_id: reviewer.id,
      comments: 'Test comment 1'
    )
  end

  let(:toc2) do
    Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL456M',
      title: 'Test Book 2',
      status: :verified,
      contributor_id: contributor.id,
      reviewer_id: reviewer.id,
      comments: 'Test comment 2'
    )
  end

  before do
    assign(:tocs, [toc1, toc2])
  end

  context 'when user is an admin' do
    before do
      allow(view).to receive(:current_user).and_return(admin_user)
      render
    end

    it 'displays contributor column header' do
      expect(rendered).to have_selector('th', text: 'Contributor')
    end

    it 'displays reviewer column header' do
      expect(rendered).to have_selector('th', text: 'Reviewer')
    end

    it 'displays contributor name instead of ID' do
      expect(rendered).to have_content('John Contributor')
    end

    it 'displays reviewer name instead of ID' do
      expect(rendered).to have_content('Jane Reviewer')
    end

    it 'displays contributor ID when user has no name' do
      contributor_no_name = User.create!(email: 'no_name@example.com', password: 'password', name: nil)
      toc_no_name = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL789M',
        title: 'Test Book 3',
        status: :empty,
        contributor_id: contributor_no_name.id
      )
      assign(:tocs, [toc_no_name])
      render
      expect(rendered).to have_content(contributor_no_name.id.to_s)
    end
  end

  context 'when user is not an admin' do
    before do
      allow(view).to receive(:current_user).and_return(regular_user)
      render
    end

    it 'does not display contributor column header' do
      expect(rendered).not_to have_selector('th', text: 'Contributor')
    end

    it 'does not display reviewer column header' do
      expect(rendered).not_to have_selector('th', text: 'Reviewer')
    end

    it 'does not display contributor name' do
      expect(rendered).not_to have_content('John Contributor')
    end

    it 'does not display reviewer name' do
      expect(rendered).not_to have_content('Jane Reviewer')
    end
  end

  context 'when user is nil (not logged in)' do
    before do
      allow(view).to receive(:current_user).and_return(nil)
      render
    end

    it 'does not display contributor column header' do
      expect(rendered).not_to have_selector('th', text: 'Contributor')
    end

    it 'does not display reviewer column header' do
      expect(rendered).not_to have_selector('th', text: 'Reviewer')
    end
  end

  context 'common elements visible to all users' do
    before do
      allow(view).to receive(:current_user).and_return(regular_user)
      render
    end

    it 'displays title column' do
      expect(rendered).to have_selector('th', text: 'Title')
      expect(rendered).to have_content('Test Book 1')
      expect(rendered).to have_content('Test Book 2')
    end

    it 'displays status column' do
      expect(rendered).to have_selector('th', text: 'Status')
    end

    it 'displays comments column' do
      expect(rendered).to have_selector('th', text: 'Comments')
      expect(rendered).to have_content('Test comment 1')
      expect(rendered).to have_content('Test comment 2')
    end

    it 'displays link to search publications' do
      expect(rendered).to have_link('Search Publications', href: publications_search_path)
    end
  end
end
