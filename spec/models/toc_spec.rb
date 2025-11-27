require 'rails_helper'

RSpec.describe Toc, type: :model do
  describe 'associations' do
    it 'belongs to manifestation optionally' do
      toc = Toc.new(book_uri: 'http://openlibrary.org/books/OL123M', title: 'Test Book')
      expect(toc.manifestation).to be_nil
      expect(toc.valid?).to be true
    end

    it 'belongs to contributor (User) optionally' do
      toc = Toc.new(book_uri: 'http://openlibrary.org/books/OL123M', title: 'Test Book')
      expect(toc.contributor).to be_nil
      expect(toc.valid?).to be true
    end

    it 'belongs to reviewer (User) optionally' do
      toc = Toc.new(book_uri: 'http://openlibrary.org/books/OL123M', title: 'Test Book')
      expect(toc.reviewer).to be_nil
      expect(toc.valid?).to be true
    end

    it 'can have a contributor assigned' do
      user = User.create!(email: 'contributor@example.com', password: 'password', name: 'John Contributor')
      toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book',
        contributor_id: user.id
      )
      expect(toc.contributor).to eq(user)
      expect(toc.contributor.name).to eq('John Contributor')
    end

    it 'can have a reviewer assigned' do
      user = User.create!(email: 'reviewer@example.com', password: 'password', name: 'Jane Reviewer')
      toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book',
        reviewer_id: user.id
      )
      expect(toc.reviewer).to eq(user)
      expect(toc.reviewer.name).to eq('Jane Reviewer')
    end
  end

  describe 'enums' do
    it 'defines status enum with correct values' do
      expect(Toc.statuses).to eq({
        'empty' => 'empty',
        'pages_marked' => 'pages_marked',
        'transcribed' => 'transcribed',
        'verified' => 'verified',
        'error' => 'error'
      })
    end
  end

  describe 'database columns' do
    subject { Toc.new }

    it 'has book_uri column' do
      expect(subject).to respond_to(:book_uri)
    end

    it 'has toc_body column' do
      expect(subject).to respond_to(:toc_body)
    end

    it 'has status column' do
      expect(subject).to respond_to(:status)
    end

    it 'has toc_page_urls column' do
      expect(subject).to respond_to(:toc_page_urls)
    end

    it 'has no_explicit_toc column' do
      expect(subject).to respond_to(:no_explicit_toc)
    end

    it 'has title column' do
      expect(subject).to respond_to(:title)
    end

    it 'has comments column' do
      expect(subject).to respond_to(:comments)
    end
  end

  describe 'toc_page_urls field' do
    it 'can store multiple URLs as text' do
      toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book',
        toc_page_urls: "https://archive.org/download/book/page1.jpg\nhttps://archive.org/download/book/page2.jpg"
      )
      expect(toc.toc_page_urls).to include('page1.jpg')
      expect(toc.toc_page_urls).to include('page2.jpg')
    end

    it 'allows nil value for toc_page_urls' do
      toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book',
        toc_page_urls: nil
      )
      expect(toc.toc_page_urls).to be_nil
    end
  end

  describe 'no_explicit_toc field' do
    it 'defaults to false' do
      toc = Toc.new(book_uri: 'http://openlibrary.org/books/OL123M', title: 'Test Book')
      expect(toc.no_explicit_toc).to eq(false)
    end

    it 'can be set to true' do
      toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL124M',
        title: 'Test Book',
        no_explicit_toc: true
      )
      expect(toc.no_explicit_toc).to eq(true)
    end

    it 'has a default value and is not nullable' do
      # Verify the column has proper constraints
      column = Toc.columns.find { |c| c.name == 'no_explicit_toc' }
      expect(column.default).to eq('0') # SQLite stores false as '0'
      expect(column.null).to eq(false)
    end
  end

  describe 'status transitions' do
    let(:toc) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL126M', title: 'Test Book') }

    it 'defaults to empty status' do
      expect(toc.status).to eq('empty')
      expect(toc.empty?).to be true
    end

    it 'allows transition from empty to pages_marked' do
      toc.status = :empty
      toc.save!
      toc.status = :pages_marked
      expect(toc.save).to eq(true)
      expect(toc.status).to eq('pages_marked')
      expect(toc.pages_marked?).to be true
    end

    it 'can transition to pages_marked when toc_page_urls are set' do
      toc.status = :empty
      toc.toc_page_urls = 'https://archive.org/download/book/page1.jpg'
      toc.status = :pages_marked
      expect(toc.save).to eq(true)
    end

    it 'can transition to pages_marked when no_explicit_toc is true' do
      toc.status = :empty
      toc.no_explicit_toc = true
      toc.status = :pages_marked
      expect(toc.save).to eq(true)
    end
  end
end
