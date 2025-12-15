require 'rails_helper'

RSpec.describe "tocs/edit.html.haml", type: :view do
  let(:user) { User.create!(email: 'test@example.com', password: 'password') }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'with imported subjects' do
    let(:toc) do
      Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/1342',
        title: 'Pride and Prejudice',
        imported_subjects: "Fiction\nRomance\nEngland -- Social life and customs"
      )
    end

    before do
      assign(:toc, toc)
      assign(:authors, [])
      render
    end

    it 'displays imported subjects' do
      expect(rendered).to have_selector('textarea#imported_subjects')
      expect(rendered).to have_content('Fiction')
    end

    it 'displays auto-match button for persisted toc with imported subjects' do
      expect(rendered).to have_selector('button#auto_match_subjects')
    end
  end

  context 'without imported subjects' do
    let(:toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book'
      )
    end

    before do
      assign(:toc, toc)
      assign(:authors, [])
      render
    end

    it 'does not display auto-match button when no imported subjects' do
      expect(rendered).not_to have_selector('button#auto_match_subjects')
    end
  end

  context 'with empty status and imported subjects' do
    let(:toc) do
      Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/84',
        title: 'Frankenstein',
        imported_subjects: "Science fiction\nHorror tales\nMonsters -- Fiction",
        status: :empty
      )
    end

    before do
      assign(:toc, toc)
      assign(:authors, [])
      render
    end

    it 'displays auto-match button for empty toc with imported subjects' do
      expect(rendered).to have_selector('button#auto_match_subjects')
    end

    it 'includes auto-match JavaScript click handler' do
      # Verify the JavaScript code for auto-match is present
      expect(rendered).to include("$('#auto_match_subjects').click(function()")
      expect(rendered).to include("/tocs/#{toc.id}/auto_match_subjects")
    end
  end

  context 'Magic trim button' do
    let(:toc) do
      Toc.create!(
        book_uri: 'http://openlibrary.org/books/OL123M',
        title: 'Test Book'
      )
    end

    before do
      assign(:toc, toc)
      assign(:authors, [])
      render
    end

    it 'displays magic trim button for persisted toc' do
      expect(rendered).to have_selector('button#magic_trim')
      expect(rendered).to have_content(I18n.t('tocs.form.magic_trim_button'))
    end

    it 'includes magic trim JavaScript click handler' do
      # Verify the JavaScript code for magic trim is present
      expect(rendered).to include("$('#magic_trim').click(function()")
      expect(rendered).to include("var textarea = $('#toc_area')")
    end
  end

  context 'JavaScript interpolation' do
    let(:work) { Work.create!(title: 'Test Work') }
    let(:expression) { Expression.create!(title: 'Test Expression') }
    let(:manifestation) { Manifestation.create! }
    let(:embodiment) { Embodiment.create!(expression: expression, manifestation: manifestation, sequence_number: nil) }
    let(:toc) do
      Toc.create!(
        book_uri: 'https://www.gutenberg.org/ebooks/1342',
        title: 'Pride and Prejudice',
        imported_subjects: "Fiction\nRomance",
        manifestation: manifestation
      )
    end

    before do
      embodiment # Force creation of embodiment before rendering
      assign(:toc, toc)
      assign(:authors, [])
      render
    end

    it 'does not contain ERB-style interpolation tags in JavaScript' do
      # Verify no ERB tags are present in the rendered output
      expect(rendered).not_to include('<%=')
      expect(rendered).not_to include('%>')
    end

    it 'properly interpolates the auto-match subjects URL' do
      # Verify the URL is properly interpolated and contains the actual path
      expect(rendered).to include("url: '/tocs/#{toc.id}/auto_match_subjects'")
    end

    it 'properly interpolates the embodiment ID' do
      # Verify the embodiment ID is properly interpolated
      expect(rendered).to include("var embodimentId = '#{embodiment.id}'")
    end

    it 'properly interpolates the I18n accept_match text' do
      # Verify the I18n text is properly interpolated
      expected_text = I18n.t('tocs.form.subjects_section.accept_match')
      expect(rendered).to include("button.text('#{expected_text}')")
    end
  end

  context 'Simplified OCR section with scan items' do
    context 'when TOC has marked pages (OpenLibrary)' do
      let(:toc) do
        Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL123M',
          title: 'Test Book with Scans',
          status: :pages_marked,
          toc_page_urls: "https://archive.org/download/book1/page1.jpg\nhttps://archive.org/download/book1/page2.jpg\nhttps://archive.org/download/book1/page3.jpg"
        )
      end

      before do
        assign(:toc, toc)
        assign(:authors, [])
        assign(:is_gutenberg, false)
        render
      end

      it 'displays the toc-scans container' do
        expect(rendered).to have_selector('.toc-scans')
      end

      it 'displays the correct number of scan items' do
        expect(rendered).to have_selector('.scan-item', count: 3)
      end

      it 'displays scan images with correct URLs and scale' do
        expect(rendered).to have_selector('img.scan-image[src="https://archive.org/download/book1/page1.jpg?scale=8"]')
        expect(rendered).to have_selector('img.scan-image[src="https://archive.org/download/book1/page2.jpg?scale=8"]')
        expect(rendered).to have_selector('img.scan-image[src="https://archive.org/download/book1/page3.jpg?scale=8"]')
      end

      it 'displays Extract Text button for each scan' do
        expect(rendered).to have_button(I18n.t('tocs.form.ocr_section.extract_text_button'), count: 3)
      end

      it 'displays paste button for each scan (initially hidden in result container)' do
        expect(rendered).to have_button(I18n.t('tocs.form.ocr_section.paste_button'), count: 3, visible: :all)
      end

      it 'hides OCR result containers by default' do
        expect(rendered).to have_selector('.ocr-result-container[style*="display: none"]', count: 3, visible: :all)
      end

      it 'displays the zoom modal' do
        expect(rendered).to have_selector('#scanZoomModal.modal')
        expect(rendered).to have_selector('#scanZoomModalLabel')
        expect(rendered).to have_selector('#scanZoomImage')
      end

      it 'includes JavaScript click handler for scan images' do
        expect(rendered).to include("$('.scan-image').click(function()")
        expect(rendered).to include("var imageUrl = $(this).data('url')")
        expect(rendered).to include("$('#scanZoomModal').modal('show')")
      end

      it 'includes JavaScript handler for Extract Text buttons' do
        expect(rendered).to include("$('.extract-text-btn').click(function()")
      end

      it 'includes JavaScript handler for paste buttons' do
        expect(rendered).to include("$('.paste-result-btn').click(function()")
      end

      it 'displays page numbers for each scan' do
        expect(rendered).to have_content(I18n.t('tocs.show.page_number', number: 1))
        expect(rendered).to have_content(I18n.t('tocs.show.page_number', number: 2))
        expect(rendered).to have_content(I18n.t('tocs.show.page_number', number: 3))
      end
    end

    context 'when TOC has no marked pages' do
      let(:toc) do
        Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL123M',
          title: 'Test Book without Scans',
          status: :empty
        )
      end

      before do
        assign(:toc, toc)
        assign(:authors, [])
        assign(:is_gutenberg, false)
        render
      end

      it 'does not display the toc-scans container' do
        expect(rendered).not_to have_selector('.toc-scans')
      end

      it 'does not display the zoom modal' do
        expect(rendered).not_to have_selector('#scanZoomModal.modal')
      end
    end
  end
end
