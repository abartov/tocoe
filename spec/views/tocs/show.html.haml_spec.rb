require 'rails_helper'

RSpec.describe "tocs/show.html.haml", type: :view do
  let(:contributor) { User.create!(email: 'contributor@example.com', password: 'password', name: 'John Contributor') }
  let(:reviewer) { User.create!(email: 'reviewer@example.com', password: 'password', name: 'Jane Reviewer') }
  let(:admin_user) { User.create!(email: 'admin@example.com', password: 'password', name: 'Admin User', admin: true) }
  let(:regular_user) { User.create!(email: 'user@example.com', password: 'password', name: 'Regular User', admin: false) }

  let(:toc) do
    Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Book',
      status: :empty,
      contributor_id: contributor.id,
      reviewer_id: reviewer.id,
      comments: 'Test comment'
    )
  end

  before do
    assign(:toc, toc)
    assign(:manifestation, nil)
  end

  context 'when user is an admin' do
    before do
      allow(view).to receive(:current_user).and_return(admin_user)
      render
    end

    it 'displays contributor label' do
      expect(rendered).to have_content('Contributor')
    end

    it 'displays reviewer label' do
      expect(rendered).to have_content('Reviewer')
    end

    it 'displays contributor name instead of ID' do
      expect(rendered).to have_content('John Contributor')
    end

    it 'displays reviewer name instead of ID' do
      expect(rendered).to have_content('Jane Reviewer')
    end

    context 'when contributor has no name' do
      it 'displays contributor ID as fallback' do
        contributor_no_name = User.create!(email: 'no_name@example.com', password: 'password', name: nil)
        toc_no_name = Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL456M',
          title: 'Test Book',
          status: :empty,
          contributor_id: contributor_no_name.id
        )
        assign(:toc, toc_no_name)
        assign(:manifestation, nil)
        allow(view).to receive(:current_user).and_return(admin_user)
        render
        expect(rendered).to match(/Contributor.*#{contributor_no_name.id}/m)
      end
    end

    context 'when contributor is nil' do
      before do
        toc.update!(contributor_id: nil)
        assign(:toc, toc)
        render
      end

      it 'displays nothing for contributor value' do
        # The view should render the label but no value or ID
        expect(rendered).to have_content('Contributor')
        # Should not show 'nil' or any ID
        expect(rendered).not_to have_content('nil')
      end
    end
  end

  context 'when user is not an admin' do
    before do
      allow(view).to receive(:current_user).and_return(regular_user)
      render
    end

    it 'does not display contributor label' do
      # We need to be careful here - "Contributor" might appear elsewhere
      # So we check that the specific paragraph with the label is not present
      expect(rendered).not_to match(/<b>Contributor<\/b>/)
    end

    it 'does not display reviewer label' do
      expect(rendered).not_to match(/<b>Reviewer<\/b>/)
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

    it 'does not display contributor information' do
      expect(rendered).not_to match(/<b>Contributor<\/b>/)
      expect(rendered).not_to have_content('John Contributor')
    end

    it 'does not display reviewer information' do
      expect(rendered).not_to match(/<b>Reviewer<\/b>/)
      expect(rendered).not_to have_content('Jane Reviewer')
    end
  end

  context 'common elements visible to all users' do
    before do
      allow(view).to receive(:current_user).and_return(regular_user)
      render
    end

    it 'displays book title and URI' do
      expect(rendered).to have_content('Test Book')
      expect(rendered).to have_content('http://openlibrary.org/books/OL123M')
    end

    it 'displays status badge' do
      expect(rendered).to have_selector('.status-badge')
      expect(rendered).to have_content('Empty')
    end

    it 'displays comments' do
      expect(rendered).to have_content('Comments')
      expect(rendered).to have_content('Test comment')
    end
  end

  context 'Toc-level authors' do
    let(:author1) { Person.create!(name: 'Author One') }
    let(:author2) { Person.create!(name: 'Author Two') }
    let(:toc_with_authors) do
      toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL789M',
        title: 'Book With Authors',
        status: :empty
      )
      PeopleToc.create!(person: author1, toc: toc)
      PeopleToc.create!(person: author2, toc: toc)
      toc
    end

    before do
      assign(:toc, toc_with_authors)
      assign(:manifestation, nil)
      allow(view).to receive(:current_user).and_return(regular_user)
      render
    end

    it 'displays the authors label' do
      expect(rendered).to have_content('Authors:')
    end

    it 'displays author names as comma-separated list' do
      expect(rendered).to have_content('Author One, Author Two')
    end
  end

  context 'Toc without authors' do
    before do
      assign(:toc, toc)
      assign(:manifestation, nil)
      allow(view).to receive(:current_user).and_return(regular_user)
      render
    end

    it 'does not display authors section when there are no authors' do
      expect(rendered).not_to match(/<strong>.*Authors:.*<\/strong>/)
    end
  end

  context 'ToC body preview' do
    let(:toc_with_body) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL456M',
        title: 'Book With ToC',
        status: :transcribed,
        toc_body: "# The Great Gatsby || F. Scott Fitzgerald\n## Chapter 1\n# Part Two /"
      )
    end

    before do
      assign(:toc, toc_with_body)
      assign(:manifestation, nil)
      allow(view).to receive(:current_user).and_return(regular_user)
      render
    end

    it 'displays toc body as HTML preview with hierarchical headings' do
      expect(rendered).to have_selector('.toc-preview')
      expect(rendered).to have_selector('h1.toc-entry', text: /The Great Gatsby/)
      expect(rendered).to have_selector('h2.toc-entry', text: 'Chapter 1')
      expect(rendered).to have_selector('h1.toc-section', text: 'Part Two')
    end

    it 'displays author names in toc preview' do
      expect(rendered).to have_selector('.toc-author', text: 'F. Scott Fitzgerald')
    end
  end

  context 'when toc body is empty' do
    before do
      allow(view).to receive(:current_user).and_return(regular_user)
      render
    end

    it 'does not display toc preview section' do
      expect(rendered).not_to have_selector('.toc-preview')
    end
  end
end
