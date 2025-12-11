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

    it 'defines source enum with correct values' do
      expect(Toc.sources).to eq({
        'openlibrary' => 0,
        'gutenberg' => 1,
        'local_upload' => 2
      })
    end
  end

  describe 'source field automatic population' do
    it 'automatically sets source to openlibrary for OpenLibrary URIs' do
      toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book'
      )
      expect(toc.source).to eq('openlibrary')
      expect(toc.openlibrary?).to be true
    end

    it 'automatically sets source to gutenberg for Gutenberg URIs' do
      toc = Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/1234',
        title: 'Test Book'
      )
      expect(toc.source).to eq('gutenberg')
      expect(toc.gutenberg?).to be true
    end

    it 'does not override manually set source' do
      toc = Toc.new(
        book_uri: 'http://openlibrary.org/books/OL456M',
        title: 'Test Book',
        source: :local_upload
      )
      toc.save!
      expect(toc.source).to eq('local_upload')
    end

    it 'does not set source if book_uri is blank' do
      toc = Toc.new(title: 'Test Book')
      toc.save!
      expect(toc.source).to be_nil
    end

    it 'updates source when book_uri is changed to gutenberg' do
      toc = Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL789M',
        title: 'Test Book'
      )
      expect(toc.source).to eq('openlibrary')

      toc.book_uri = 'https://www.gutenberg.org/ebooks/5678'
      toc.source = nil # Clear the source to allow automatic setting
      toc.save!
      expect(toc.source).to eq('gutenberg')
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

    it 'has source column' do
      expect(subject).to respond_to(:source)
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

    it 'has imported_subjects column' do
      expect(subject).to respond_to(:imported_subjects)
    end
  end

  describe 'imported_subjects field' do
    it 'can store multiple subjects as newline-separated text' do
      toc = Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/1234',
        title: 'Test Book',
        imported_subjects: "Fiction\nAdventure\nHistorical fiction"
      )
      expect(toc.imported_subjects).to include('Fiction')
      expect(toc.imported_subjects).to include('Adventure')
      expect(toc.imported_subjects).to include('Historical fiction')
    end

    it 'allows nil value for imported_subjects' do
      toc = Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/5678',
        title: 'Test Book',
        imported_subjects: nil
      )
      expect(toc.imported_subjects).to be_nil
    end

    it 'can be updated to remove subjects' do
      toc = Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/9999',
        title: 'Test Book',
        imported_subjects: "Fiction\nAdventure\nHistorical fiction"
      )

      subjects = toc.imported_subjects.split("\n")
      subjects.delete("Adventure")
      toc.imported_subjects = subjects.join("\n")
      toc.save!

      expect(toc.imported_subjects).not_to include('Adventure')
      expect(toc.imported_subjects).to include('Fiction')
      expect(toc.imported_subjects).to include('Historical fiction')
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

  describe 'validations' do
    let(:contributor) { User.create!(email: 'contributor@example.com', password: 'password', name: 'Contributor') }
    let(:reviewer) { User.create!(email: 'reviewer@example.com', password: 'password', name: 'Reviewer') }

    describe 'contributor cannot be reviewer' do
      it 'is invalid when contributor and reviewer are the same user' do
        toc = Toc.new(
          book_uri: 'http://openlibrary.org/books/OL130M',
          title: 'Test Book',
          status: :verified,
          contributor_id: contributor.id,
          reviewer_id: contributor.id
        )
        expect(toc.valid?).to be false
        expect(toc.errors[:reviewer_id]).to include('cannot be the same as the contributor')
      end

      it 'is valid when contributor and reviewer are different users' do
        toc = Toc.new(
          book_uri: 'http://openlibrary.org/books/OL131M',
          title: 'Test Book',
          status: :verified,
          contributor_id: contributor.id,
          reviewer_id: reviewer.id
        )
        expect(toc.valid?).to be true
      end

      it 'is valid when there is no reviewer (not verified yet)' do
        toc = Toc.new(
          book_uri: 'http://openlibrary.org/books/OL132M',
          title: 'Test Book',
          status: :transcribed,
          contributor_id: contributor.id,
          reviewer_id: nil
        )
        expect(toc.valid?).to be true
      end

      it 'is valid when there is no contributor' do
        toc = Toc.new(
          book_uri: 'http://openlibrary.org/books/OL133M',
          title: 'Test Book',
          status: :verified,
          contributor_id: nil,
          reviewer_id: reviewer.id
        )
        expect(toc.valid?).to be true
      end
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

  describe 'status timestamps' do
    let(:toc) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL127M', title: 'Test Book') }

    describe 'transcribed_at' do
      it 'is set when status changes to transcribed' do
        expect(toc.transcribed_at).to be_nil

        toc.status = :transcribed
        toc.save!

        expect(toc.transcribed_at).to be_present
        expect(toc.transcribed_at).to be_within(1.second).of(Time.current)
      end

      it 'is not set when status is not transcribed' do
        toc.status = :pages_marked
        toc.save!

        expect(toc.transcribed_at).to be_nil
      end

      it 'is not updated when status changes from transcribed to another status' do
        toc.status = :transcribed
        toc.save!
        original_time = toc.transcribed_at

        toc.status = :verified
        toc.save!

        expect(toc.transcribed_at).to eq(original_time)
      end

      it 'is not updated when saving without status change' do
        toc.status = :transcribed
        toc.save!
        original_time = toc.transcribed_at

        toc.title = 'Updated Title'
        toc.save!

        expect(toc.transcribed_at).to eq(original_time)
      end
    end

    describe 'verified_at' do
      it 'is set when status changes to verified' do
        expect(toc.verified_at).to be_nil

        toc.status = :verified
        toc.save!

        expect(toc.verified_at).to be_present
        expect(toc.verified_at).to be_within(1.second).of(Time.current)
      end

      it 'is not set when status is not verified' do
        toc.status = :transcribed
        toc.save!

        expect(toc.verified_at).to be_nil
      end

      it 'is not updated when saving without status change' do
        toc.status = :verified
        toc.save!
        original_time = toc.verified_at

        toc.title = 'Updated Title'
        toc.save!

        expect(toc.verified_at).to eq(original_time)
      end
    end

    describe 'full workflow' do
      it 'sets both timestamps through the complete workflow' do
        # Start: empty
        expect(toc.status).to eq('empty')
        expect(toc.transcribed_at).to be_nil
        expect(toc.verified_at).to be_nil

        # Mark as pages_marked
        toc.status = :pages_marked
        toc.save!
        expect(toc.transcribed_at).to be_nil
        expect(toc.verified_at).to be_nil

        # Mark as transcribed
        toc.status = :transcribed
        toc.save!
        expect(toc.transcribed_at).to be_present
        expect(toc.verified_at).to be_nil

        transcribed_time = toc.transcribed_at

        # Mark as verified
        toc.status = :verified
        toc.save!
        expect(toc.transcribed_at).to eq(transcribed_time)
        expect(toc.verified_at).to be_present
        expect(toc.verified_at).to be >= transcribed_time
      end
    end
  end
end
