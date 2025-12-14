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

    it 'displays contributor information' do
      expect(rendered).to have_selector('.toc-meta', text: /👤/)
    end

    it 'displays contributor name for admins' do
      # Contributor is shown to admins in the card layout
      expect(rendered).to have_content('John Contributor')
    end

    it 'displays contributor name instead of ID' do
      expect(rendered).to have_content('John Contributor')
    end

    it 'does not display reviewer in index view' do
      # Reviewer info is not shown in the index card layout
      expect(rendered).not_to have_content('Jane Reviewer')
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

    it 'does not display contributor information to non-admin' do
      # Contributor info is only shown to admins
      expect(rendered).not_to have_content('John Contributor')
    end

    it 'does not display reviewer information to non-admin' do
      # Reviewer info is only shown to admins
      expect(rendered).not_to have_content('Jane Reviewer')
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

    it 'does not display contributor information when not logged in' do
      # Contributor info is only shown to admins
      expect(rendered).not_to have_content('John Contributor')
    end

    it 'does not display reviewer information when not logged in' do
      # Reviewer info is only shown to admins
      expect(rendered).not_to have_content('Jane Reviewer')
    end
  end

  context 'common elements visible to all users' do
    before do
      allow(view).to receive(:current_user).and_return(regular_user)
      render
    end

    it 'displays titles in card layout' do
      expect(rendered).to have_selector('.toc-card')
      expect(rendered).to have_content('Test Book 1')
      expect(rendered).to have_content('Test Book 2')
    end

    it 'displays status badges' do
      expect(rendered).to have_selector('.status-badge')
    end

    it 'displays comments in cards' do
      expect(rendered).to have_selector('.toc-comments')
      expect(rendered).to have_content('Test comment 1')
      expect(rendered).to have_content('Test comment 2')
    end

    it 'displays link to search publications' do
      expect(rendered).to have_link('Search Publications', href: publications_search_path)
    end
  end

  context 'author display' do
    before do
      allow(view).to receive(:current_user).and_return(regular_user)
    end

    it 'displays author names when TOC has authors' do
      author1 = Person.create!(name: 'Jane Austen')
      author2 = Person.create!(name: 'Charles Dickens')
      toc_with_authors = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL999M',
        title: 'Book with Authors',
        status: :empty
      )
      PeopleToc.create!(person: author1, toc: toc_with_authors)
      PeopleToc.create!(person: author2, toc: toc_with_authors)

      assign(:tocs, [toc_with_authors])
      render

      expect(rendered).to have_content('Jane Austen, Charles Dickens')
      expect(rendered).to have_selector('.toc-meta', text: /✍️/)
    end

    it 'displays single author correctly' do
      author = Person.create!(name: 'William Shakespeare')
      toc_with_author = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL888M',
        title: 'Book with One Author',
        status: :empty
      )
      PeopleToc.create!(person: author, toc: toc_with_author)

      assign(:tocs, [toc_with_author])
      render

      expect(rendered).to have_content('William Shakespeare')
      expect(rendered).to have_selector('.toc-meta', text: /✍️/)
    end

    it 'does not display author section when TOC has no authors' do
      toc_no_authors = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL777M',
        title: 'Book without Authors',
        status: :empty
      )

      assign(:tocs, [toc_no_authors])
      render

      # Author emoji should not be present
      toc_card = rendered.match(/<div[^>]*class="[^"]*toc-card[^"]*"[^>]*>.*?Book without Authors.*?<\/div>/m).to_s
      expect(toc_card).not_to include('✍️')
    end

    it 'handles TOCs with multiple authors correctly' do
      author1 = Person.create!(name: 'Author One')
      author2 = Person.create!(name: 'Author Two')
      author3 = Person.create!(name: 'Author Three')
      toc_multiple_authors = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL666M',
        title: 'Book with Multiple Authors',
        status: :empty
      )
      PeopleToc.create!(person: author1, toc: toc_multiple_authors)
      PeopleToc.create!(person: author2, toc: toc_multiple_authors)
      PeopleToc.create!(person: author3, toc: toc_multiple_authors)

      assign(:tocs, [toc_multiple_authors])
      render

      expect(rendered).to have_content('Author One, Author Two, Author Three')
    end
  end
end
