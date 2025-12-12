require 'rails_helper'

RSpec.describe PeopleToc, type: :model do
  describe 'associations' do
    it 'belongs to person' do
      person = Person.create!(name: 'Test Author')
      toc = Toc.create!(title: 'Test TOC', book_uri: 'http://example.com/book')
      people_toc = PeopleToc.create!(person: person, toc: toc)

      expect(people_toc.person).to eq(person)
    end

    it 'belongs to toc' do
      person = Person.create!(name: 'Test Author')
      toc = Toc.create!(title: 'Test TOC', book_uri: 'http://example.com/book')
      people_toc = PeopleToc.create!(person: person, toc: toc)

      expect(people_toc.toc).to eq(toc)
    end
  end

  describe 'validations' do
    it 'validates uniqueness of person_id scoped to toc_id' do
      person = Person.create!(name: 'Test Author')
      toc = Toc.create!(title: 'Test TOC', book_uri: 'http://example.com/book')

      PeopleToc.create!(person: person, toc: toc)
      duplicate = PeopleToc.new(person: person, toc: toc)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:person_id]).to include('has already been taken')
    end
  end
end
