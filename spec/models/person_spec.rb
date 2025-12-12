require 'rails_helper'

RSpec.describe Person, type: :model do
  describe 'validations' do
    it 'validates presence of name' do
      person = Person.new(name: nil)
      expect(person.valid?).to be false
      expect(person.errors[:name]).to include('cannot be blank')
    end

    it 'is valid with a name' do
      person = Person.new(name: 'Test Author')
      expect(person.valid?).to be true
    end
  end

  describe 'associations' do
    it 'has many people_works' do
      person = Person.create!(name: 'Test Author')
      work1 = Work.create!(title: 'Work One')
      work2 = Work.create!(title: 'Work Two')

      PeopleWork.create!(person: person, work: work1)
      PeopleWork.create!(person: person, work: work2)

      expect(person.people_works.count).to eq(2)
    end

    it 'has many works through people_works' do
      person = Person.create!(name: 'Test Author')
      work1 = Work.create!(title: 'Work One')
      work2 = Work.create!(title: 'Work Two')

      PeopleWork.create!(person: person, work: work1)
      PeopleWork.create!(person: person, work: work2)

      expect(person.works.count).to eq(2)
      expect(person.works).to include(work1)
      expect(person.works).to include(work2)
    end

    it 'has many people_tocs' do
      person = Person.create!(name: 'Test Author')
      toc1 = Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'TOC One')
      toc2 = Toc.create!(book_uri: 'http://openlibrary.org/books/OL2M', title: 'TOC Two')

      PeopleToc.create!(person: person, toc: toc1)
      PeopleToc.create!(person: person, toc: toc2)

      expect(person.people_tocs.count).to eq(2)
    end

    it 'has many tocs through people_tocs' do
      person = Person.create!(name: 'Test Author')
      toc1 = Toc.create!(book_uri: 'http://openlibrary.org/books/OL1M', title: 'TOC One')
      toc2 = Toc.create!(book_uri: 'http://openlibrary.org/books/OL2M', title: 'TOC Two')

      PeopleToc.create!(person: person, toc: toc1)
      PeopleToc.create!(person: person, toc: toc2)

      expect(person.tocs.count).to eq(2)
      expect(person.tocs).to include(toc1)
      expect(person.tocs).to include(toc2)
    end
  end

  describe 'authority identifiers' do
    it 'can store VIAF ID' do
      person = Person.create!(name: 'Test Author', viaf_id: 12345678)
      expect(person.viaf_id).to eq(12345678)
    end

    it 'can store Wikidata Q number' do
      person = Person.create!(name: 'Test Author', wikidata_q: 87654321)
      expect(person.wikidata_q).to eq(87654321)
    end

    it 'can store OpenLibrary ID' do
      person = Person.create!(name: 'Test Author', openlibrary_id: '/authors/OL123A')
      expect(person.openlibrary_id).to eq('/authors/OL123A')
    end

    it 'can store Library of Congress ID' do
      person = Person.create!(name: 'Test Author', loc_id: 'n79021164')
      expect(person.loc_id).to eq('n79021164')
    end

    it 'can store Project Gutenberg author ID' do
      person = Person.create!(name: 'Test Author', gutenberg_id: 4527)
      expect(person.gutenberg_id).to eq(4527)
    end

    it 'can store multiple authority identifiers on the same person' do
      person = Person.create!(
        name: 'Test Author',
        viaf_id: 12345678,
        wikidata_q: 87654321,
        openlibrary_id: '/authors/OL123A',
        loc_id: 'n79021164',
        gutenberg_id: 4527
      )

      expect(person.viaf_id).to eq(12345678)
      expect(person.wikidata_q).to eq(87654321)
      expect(person.openlibrary_id).to eq('/authors/OL123A')
      expect(person.loc_id).to eq('n79021164')
      expect(person.gutenberg_id).to eq(4527)
    end
  end
end
