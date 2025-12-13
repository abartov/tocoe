require 'rails_helper'

RSpec.feature 'Public TOCs browsing', type: :feature do
  scenario 'unauthenticated user can browse verified TOCs' do
    verified_toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL1M',
      title: 'Test Book',
      status: :verified,
      toc_body: "# Chapter 1\n# Chapter 2"
    )

    pending_toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL2M',
      title: 'Pending Book',
      status: :pages_marked
    )

    # Don't sign in
    visit '/browse'

    expect(page).to have_content('Browse Verified Tables of Contents')
    expect(page).to have_content('Test Book')
    expect(page).not_to have_content('Pending Book')
    expect(page).to have_link('View TOC')
  end

  scenario 'unauthenticated user can view individual verified TOC' do
    verified_toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL1M',
      title: 'Test Book',
      status: :verified,
      toc_body: "# Chapter 1\n# Chapter 2"
    )

    visit "/browse/#{verified_toc.id}"

    expect(page).to have_content('Test Book')
    expect(page).to have_content('Chapter 1')
    expect(page).to have_content('Chapter 2')
    expect(page).to have_content('Verified')
  end

  scenario 'unauthenticated user cannot see edit/delete buttons' do
    verified_toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL1M',
      title: 'Test Book',
      status: :verified,
      toc_body: "# Chapter 1\n# Chapter 2"
    )

    visit "/browse/#{verified_toc.id}"

    expect(page).not_to have_link('Edit')
    expect(page).not_to have_link('Destroy')
    expect(page).not_to have_button('Delete')
  end

  scenario 'unauthenticated user cannot see manage subject headings buttons' do
    # Create manifestation with embodiment
    manifestation = Manifestation.create!(title: 'Test Manifestation')
    work = Work.create!(title: 'Test Work')
    expression = Expression.create!(title: 'Test Expression')
    work.expressions << expression
    embodiment = Embodiment.create!(
      expression: expression,
      manifestation: manifestation,
      sequence_number: nil
    )

    verified_toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL1M',
      title: 'Test Book',
      status: :verified,
      toc_body: "# Chapter 1",
      manifestation: manifestation
    )

    visit "/browse/#{verified_toc.id}"

    expect(page).not_to have_link('Manage Subject Headings')
    expect(page).not_to have_link('Manage Subject Headings for this work')
  end

  scenario 'sorting controls work on browse page' do
    toc_a = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL1M',
      title: 'Aardvark Book',
      status: :verified,
      created_at: 2.days.ago
    )

    toc_z = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL2M',
      title: 'Zebra Book',
      status: :verified,
      created_at: 1.day.ago
    )

    visit '/browse'

    # Default: created_at desc (newest first)
    toc_titles = page.all('.toc-card h3').map(&:text)
    expect(toc_titles.first).to include('Zebra Book')
    expect(toc_titles.last).to include('Aardvark Book')

    # Click sort by title
    click_link '📖 Title'

    # Should be sorted by title asc
    toc_titles = page.all('.toc-card h3').map(&:text)
    expect(toc_titles.first).to include('Aardvark Book')
    expect(toc_titles.last).to include('Zebra Book')
  end

  scenario 'sign-in banner is visible on browse page' do
    Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL1M',
      title: 'Test Book',
      status: :verified
    )

    visit '/browse'

    expect(page).to have_content('Want to contribute? Sign in to add or verify TOCs')
    expect(page).to have_link('Sign in to contribute')
  end

  scenario 'back to browse link works on show page' do
    verified_toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL1M',
      title: 'Test Book',
      status: :verified,
      toc_body: "# Chapter 1"
    )

    visit "/browse/#{verified_toc.id}"

    click_link 'Back to Browse'

    expect(page).to have_current_path('/browse')
    expect(page).to have_content('Browse Verified Tables of Contents')
  end

  scenario 'home page links to browse page' do
    Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL1M',
      title: 'Test Book',
      status: :verified
    )

    visit '/'

    expect(page).to have_link('Browse Existing TOCs')

    click_link 'Browse Existing TOCs'

    expect(page).to have_current_path('/browse')
    expect(page).to have_content('Browse Verified Tables of Contents')
  end

  scenario 'empty state message when no verified TOCs exist' do
    # Create only non-verified TOCs
    Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL1M',
      title: 'Pending Book',
      status: :pages_marked
    )

    visit '/browse'

    expect(page).to have_content('No verified TOCs available yet. Check back soon!')
  end

  scenario 'shows book source (Open Library or Gutenberg)' do
    ol_toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL1M',
      title: 'Open Library Book',
      status: :verified,
      source: :openlibrary
    )

    gutenberg_toc = Toc.create!(
      book_uri: 'https://www.gutenberg.org/ebooks/12345',
      title: 'Gutenberg Book',
      status: :verified,
      source: :gutenberg
    )

    visit '/browse'

    expect(page).to have_content('Open Library')
    expect(page).to have_content('Gutenberg')
  end
end
