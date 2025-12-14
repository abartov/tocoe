require 'rails_helper'

RSpec.feature 'Review Authors Workflow', type: :feature do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    sign_in_as(user)
  end

  scenario 'user marks TOC as transcribed and is redirected to review authors page' do
    # Create a TOC with pages marked
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Collection',
      status: :pages_marked,
      toc_body: "# Essay One || Alice Smith\n# Essay Two || Bob Jones"
    )

    # Visit the TOC show page
    visit toc_path(toc)

    # Mark as transcribed
    click_button I18n.t('tocs.show.pages_marked_alert.mark_transcribed_button')

    # Should be redirected to review_authors page
    expect(current_path).to eq(review_authors_toc_path(toc))
    expect(page).to have_content(I18n.t('tocs.review_authors.title', toc_title: 'Test Collection'))
  end

  scenario 'review authors page displays work-author pairs correctly' do
    # Create a TOC with manifestation and works
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Collection',
      status: :transcribed,
      toc_body: "# Work One || Author One\n# Work Two || [Translator Two]"
    )

    # Process the TOC to create works
    manifestation = Manifestation.create!(title: 'Test Manifestation')
    work1 = Work.create!(title: 'Work One')
    work2 = Work.create!(title: 'Work Two')
    expression1 = Expression.create!(title: 'Work One')
    expression2 = Expression.create!(title: 'Work Two')

    work1.expressions << expression1
    work2.expressions << expression2
    Embodiment.create!(expression: expression1, manifestation: manifestation, sequence_number: 1)
    Embodiment.create!(expression: expression2, manifestation: manifestation, sequence_number: 2)

    toc.update!(manifestation: manifestation)

    # Visit the review_authors page
    visit review_authors_toc_path(toc)

    # Should display both works
    expect(page).to have_content('1. Work One')
    expect(page).to have_content('2. Work Two')

    # Should display authors with correct roles
    expect(page).to have_content('Author One')
    expect(page).to have_content(I18n.t('tocs.review_authors.role_author'))
    expect(page).to have_content('Translator Two')
    expect(page).to have_content(I18n.t('tocs.review_authors.role_translator'))

    # Should have match buttons
    expect(page).to have_button(I18n.t('tocs.review_authors.match_button'), count: 2)
  end

  scenario 'review authors page shows inherited authors for works without explicit authors' do
    # Create a TOC with a book author
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Collection',
      status: :transcribed,
      toc_body: "# Chapter One\n# Chapter Two"
    )

    # Add a book author to the TOC
    book_author = Person.create!(name: 'Book Author')
    PeopleToc.create!(person: book_author, toc: toc)

    # Process the TOC to create works
    manifestation = Manifestation.create!(title: 'Test Manifestation')
    work1 = Work.create!(title: 'Chapter One')
    expression1 = Expression.create!(title: 'Chapter One')
    work1.expressions << expression1
    Embodiment.create!(expression: expression1, manifestation: manifestation, sequence_number: 1)
    toc.update!(manifestation: manifestation)

    # Visit the review_authors page
    visit review_authors_toc_path(toc)

    # Should show inherited author message
    expect(page).to have_content(I18n.t('tocs.review_authors.no_explicit_authors'))
    expect(page).to have_content(I18n.t('tocs.review_authors.inherited_authors_from_toc'))
    expect(page).to have_content('Book Author')
  end

  scenario 'review authors page shows matched status for already matched authors' do
    # Create a TOC with manifestation and works
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Collection',
      status: :transcribed,
      toc_body: "# Work One || Matched Author"
    )

    # Process the TOC to create works
    manifestation = Manifestation.create!(title: 'Test Manifestation')
    work = Work.create!(title: 'Work One')
    expression = Expression.create!(title: 'Work One')
    work.expressions << expression
    Embodiment.create!(expression: expression, manifestation: manifestation, sequence_number: 1)
    toc.update!(manifestation: manifestation)

    # Create a person and link to the work
    person = Person.create!(name: 'Matched Author')
    PeopleWork.create!(person: person, work: work)

    # Visit the review_authors page
    visit review_authors_toc_path(toc)

    # Should show matched badge instead of match button
    expect(page).to have_content(I18n.t('tocs.review_authors.matched'))
    expect(page).to have_content('Matched Author')
    expect(page).not_to have_button(I18n.t('tocs.review_authors.match_button'))
  end

  scenario 'review authors page rejects access for non-transcribed TOCs' do
    # Create a non-transcribed TOC
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Collection',
      status: :empty
    )

    # Try to visit the review_authors page
    visit review_authors_toc_path(toc)

    # Should be redirected with error
    expect(current_path).to eq(toc_path(toc))
    expect(page).to have_content(I18n.t('tocs.flash.must_be_transcribed_to_review_authors'))
  end

  scenario 'review authors page handles works with mixed author and translator roles' do
    # Create a TOC with both authors and translators
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Collection',
      status: :transcribed,
      toc_body: "# Work One || Original Author; [Translator Name]"
    )

    # Process the TOC to create works
    manifestation = Manifestation.create!(title: 'Test Manifestation')
    work = Work.create!(title: 'Work One')
    expression = Expression.create!(title: 'Work One')
    work.expressions << expression
    Embodiment.create!(expression: expression, manifestation: manifestation, sequence_number: 1)
    toc.update!(manifestation: manifestation)

    # Visit the review_authors page
    visit review_authors_toc_path(toc)

    # Should display both author and translator
    expect(page).to have_content('Original Author')
    expect(page).to have_content('Translator Name')

    # Should have two match buttons (one for author, one for translator)
    expect(page).to have_button(I18n.t('tocs.review_authors.match_button'), count: 2)

    # Should show correct role badges
    author_section = page.find('li', text: 'Original Author')
    expect(author_section).to have_content(I18n.t('tocs.review_authors.role_author'))

    translator_section = page.find('li', text: 'Translator Name')
    expect(translator_section).to have_content(I18n.t('tocs.review_authors.role_translator'))
  end

  scenario 'review authors page allows skipping for now' do
    # Create a TOC
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Collection',
      status: :transcribed,
      toc_body: "# Work One || Author One"
    )

    # Process the TOC to create works
    manifestation = Manifestation.create!(title: 'Test Manifestation')
    work = Work.create!(title: 'Work One')
    expression = Expression.create!(title: 'Work One')
    work.expressions << expression
    Embodiment.create!(expression: expression, manifestation: manifestation, sequence_number: 1)
    toc.update!(manifestation: manifestation)

    # Visit the review_authors page
    visit review_authors_toc_path(toc)

    # Click "Skip for now"
    click_link I18n.t('tocs.review_authors.skip_for_now')

    # Should be redirected to TOC show page
    expect(current_path).to eq(toc_path(toc))
  end

  scenario 'review authors page shows undo match button for matched authors' do
    # Create a TOC with manifestation and works
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Collection',
      status: :transcribed,
      toc_body: "# Work One || Matched Author"
    )

    # Process the TOC to create works
    manifestation = Manifestation.create!(title: 'Test Manifestation')
    work = Work.create!(title: 'Work One')
    expression = Expression.create!(title: 'Work One')
    work.expressions << expression
    Embodiment.create!(expression: expression, manifestation: manifestation, sequence_number: 1)
    toc.update!(manifestation: manifestation)

    # Create a person and link to the work
    person = Person.create!(name: 'Matched Author')
    PeopleWork.create!(person: person, work: work)

    # Visit the review_authors page
    visit review_authors_toc_path(toc)

    # Should show matched badge and undo button
    expect(page).to have_content(I18n.t('tocs.review_authors.matched'))
    expect(page).to have_content('Matched Author')
    expect(page).to have_button(I18n.t('tocs.review_authors.undo_match_button'))
    expect(page).not_to have_button(I18n.t('tocs.review_authors.match_button'))
  end

  scenario 'review authors page shows undo match button for matched translators' do
    # Create a TOC with a translator
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Collection',
      status: :transcribed,
      toc_body: "# Work One || [Matched Translator]"
    )

    # Process the TOC to create works
    manifestation = Manifestation.create!(title: 'Test Manifestation')
    work = Work.create!(title: 'Work One')
    expression = Expression.create!(title: 'Work One')
    work.expressions << expression
    Embodiment.create!(expression: expression, manifestation: manifestation, sequence_number: 1)
    toc.update!(manifestation: manifestation)

    # Create a person and link to the expression as a realizer
    person = Person.create!(name: 'Matched Translator')
    Realization.create!(realizer: person, expression: expression)

    # Visit the review_authors page
    visit review_authors_toc_path(toc)

    # Should show matched badge and undo button
    expect(page).to have_content(I18n.t('tocs.review_authors.matched'))
    expect(page).to have_content('Matched Translator')
    expect(page).to have_button(I18n.t('tocs.review_authors.undo_match_button'))
    expect(page).not_to have_button(I18n.t('tocs.review_authors.match_button'))
  end

  scenario 'review authors page shows undo match button for inherited matched authors' do
    # Create a TOC with a book author
    toc = Toc.create!(
      book_uri: 'http://openlibrary.org/books/OL123M',
      title: 'Test Collection',
      status: :transcribed,
      toc_body: "# Chapter One"
    )

    # Add a book author to the TOC
    book_author = Person.create!(name: 'Book Author')
    PeopleToc.create!(person: book_author, toc: toc)

    # Process the TOC to create works
    manifestation = Manifestation.create!(title: 'Test Manifestation')
    work = Work.create!(title: 'Chapter One')
    expression = Expression.create!(title: 'Chapter One')
    work.expressions << expression
    Embodiment.create!(expression: expression, manifestation: manifestation, sequence_number: 1)
    toc.update!(manifestation: manifestation)

    # Link the book author to the work
    PeopleWork.create!(person: book_author, work: work)

    # Visit the review_authors page
    visit review_authors_toc_path(toc)

    # Should show inherited author with matched status and undo button
    expect(page).to have_content(I18n.t('tocs.review_authors.no_explicit_authors'))
    expect(page).to have_content(I18n.t('tocs.review_authors.inherited_authors_from_toc'))
    expect(page).to have_content('Book Author')
    expect(page).to have_content(I18n.t('tocs.review_authors.matched'))
    expect(page).to have_button(I18n.t('tocs.review_authors.undo_match_button'))
  end
end
