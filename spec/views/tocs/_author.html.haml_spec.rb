require 'rails_helper'

RSpec.describe 'tocs/_author', type: :view do
  context 'with OpenLibrary author (has link)' do
    it 'renders author name as a link' do
      author = {
        'name' => 'Jane Austen',
        'link' => 'http://openlibrary.org/authors/OL21594A'
      }

      render partial: 'tocs/author', locals: { author: author }

      expect(rendered).to have_link('Jane Austen', href: 'http://openlibrary.org/authors/OL21594A')
    end
  end

  context 'with Project Gutenberg author (no link)' do
    it 'renders author name as plain text' do
      author = {
        'name' => 'Austen, Jane',
        'birth_year' => 1775,
        'death_year' => 1817,
        'link' => nil
      }

      render partial: 'tocs/author', locals: { author: author }

      expect(rendered).to have_text('Austen, Jane')
      expect(rendered).not_to have_link('Austen, Jane')
    end
  end

  context 'with author missing link key' do
    it 'renders author name as plain text' do
      author = {
        'name' => 'Unknown Author'
      }

      render partial: 'tocs/author', locals: { author: author }

      expect(rendered).to have_text('Unknown Author')
      expect(rendered).not_to have_link('Unknown Author')
    end
  end
end
