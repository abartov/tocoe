require 'rails_helper'

RSpec.describe TocsHelper, type: :helper do
  describe '#toc_markdown_to_html_preview' do
    it 'returns empty string for nil input' do
      expect(helper.toc_markdown_to_html_preview(nil)).to eq('')
    end

    it 'returns empty string for blank input' do
      expect(helper.toc_markdown_to_html_preview('')).to eq('')
    end

    it 'converts single level heading to h1' do
      markdown = "# The Great Gatsby"
      html = helper.toc_markdown_to_html_preview(markdown)

      expect(html).to include('<h1 class=\'toc-entry\'>The Great Gatsby</h1>')
    end

    it 'converts double level heading to h2' do
      markdown = "## Chapter One"
      html = helper.toc_markdown_to_html_preview(markdown)

      expect(html).to include('<h2 class=\'toc-entry\'>Chapter One</h2>')
    end

    it 'marks section headings with trailing slash' do
      markdown = "# Part One /"
      html = helper.toc_markdown_to_html_preview(markdown)

      expect(html).to include('<h1 class=\'toc-section\'>Part One</h1>')
    end

    it 'extracts and displays author names with ||' do
      markdown = "# The Great Gatsby || F. Scott Fitzgerald"
      html = helper.toc_markdown_to_html_preview(markdown)

      expect(html).to include('<h1 class=\'toc-entry\'>')
      expect(html).to include('The Great Gatsby')
      expect(html).to include('<span class=\'toc-author\'>F. Scott Fitzgerald</span>')
    end

    it 'handles multiple authors separated by semicolons' do
      markdown = "# Good Omens || Terry Pratchett; Neil Gaiman"
      html = helper.toc_markdown_to_html_preview(markdown)

      expect(html).to include('Good Omens')
      expect(html).to include('<span class=\'toc-author\'>Terry Pratchett; Neil Gaiman</span>')
    end

    it 'escapes HTML in titles and authors' do
      markdown = "# <script>alert('xss')</script> || <b>Author</b>"
      html = helper.toc_markdown_to_html_preview(markdown)

      expect(html).not_to include('<script>')
      expect(html).not_to include('<b>Author</b>')
      expect(html).to include('&lt;script&gt;')
      expect(html).to include('&lt;b&gt;Author&lt;/b&gt;')
    end

    it 'handles multi-line ToC markdown with mixed formats' do
      markdown = <<~MARKDOWN
        # Part One /
        # The Great Gatsby || F. Scott Fitzgerald
        ## Chapter 1
        ## Chapter 2
        # Part Two /
        # Another Story
      MARKDOWN

      html = helper.toc_markdown_to_html_preview(markdown)

      expect(html).to include('<h1 class=\'toc-section\'>Part One</h1>')
      expect(html).to include('<h1 class=\'toc-entry\'>')
      expect(html).to include('The Great Gatsby')
      expect(html).to include('<span class=\'toc-author\'>F. Scott Fitzgerald</span>')
      expect(html).to include('<h2 class=\'toc-entry\'>Chapter 1</h2>')
      expect(html).to include('<h2 class=\'toc-entry\'>Chapter 2</h2>')
      expect(html).to include('<h1 class=\'toc-section\'>Part Two</h1>')
      expect(html).to include('<h1 class=\'toc-entry\'>Another Story</h1>')
    end

    it 'skips empty lines' do
      markdown = <<~MARKDOWN
        # First Entry

        # Second Entry
      MARKDOWN

      html = helper.toc_markdown_to_html_preview(markdown)

      expect(html).to include('First Entry')
      expect(html).to include('Second Entry')
    end
  end
end
