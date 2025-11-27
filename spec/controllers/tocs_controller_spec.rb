require 'rails_helper'

RSpec.describe TocsController, type: :controller do
  let(:toc) { Toc.create!(book_uri: 'http://openlibrary.org/books/OL123M', title: 'Test Book') }

  describe 'GET #browse_scans' do
    context 'with valid OpenLibrary book URI' do
      let(:ol_client) { instance_double(OpenLibrary::Client) }
      let(:ia_metadata) { { imagecount: 50, title: 'Test Book', page_progression: 'lr' } }
      let(:page_images) do
        (0...20).map do |n|
          {
            page_number: n,
            url: "https://archive.org/download/test_id/page/n#{n}.jpg",
            thumb_url: "https://archive.org/download/test_id/page/n#{n}.jpg?scale=8"
          }
        end
      end

      before do
        allow(OpenLibrary::Client).to receive(:new).and_return(ol_client)
        allow(ol_client).to receive(:ia_identifier).with('OL123M').and_return('test_ia_id')
        allow(ol_client).to receive(:ia_metadata).with('test_ia_id').and_return(ia_metadata)
        allow(ol_client).to receive(:ia_page_images).and_return(page_images)
      end

      it 'fetches and displays page scans' do
        get :browse_scans, params: { id: toc.id }

        expect(response).to have_http_status(:success)
        expect(assigns(:ia_id)).to eq('test_ia_id')
        expect(assigns(:metadata)).to eq(ia_metadata)
        expect(assigns(:pages)).to eq(page_images)
      end

      it 'handles pagination' do
        get :browse_scans, params: { id: toc.id, page: 2 }

        expect(assigns(:current_page)).to eq(2)
        expect(ol_client).to have_received(:ia_page_images).with(
          'test_ia_id',
          hash_including(start_page: 20, end_page: 39)
        )
      end

      it 'parses already marked pages' do
        toc.update!(toc_page_urls: "https://archive.org/page1.jpg\nhttps://archive.org/page2.jpg")

        get :browse_scans, params: { id: toc.id }

        expect(assigns(:marked_pages)).to eq([
          'https://archive.org/page1.jpg',
          'https://archive.org/page2.jpg'
        ])
      end
    end

    context 'with invalid book URI' do
      let(:invalid_toc) { Toc.create!(book_uri: 'http://example.com/invalid', title: 'Invalid') }

      it 'redirects with error for invalid URI' do
        get :browse_scans, params: { id: invalid_toc.id }

        expect(response).to redirect_to(invalid_toc)
        expect(flash[:error]).to eq('Invalid OpenLibrary book URI')
      end
    end

    context 'when no scans available' do
      let(:ol_client) { instance_double(OpenLibrary::Client) }

      before do
        allow(OpenLibrary::Client).to receive(:new).and_return(ol_client)
        allow(ol_client).to receive(:ia_identifier).and_return(nil)
      end

      it 'redirects with error' do
        get :browse_scans, params: { id: toc.id }

        expect(response).to redirect_to(toc)
        expect(flash[:error]).to eq('No scans available for this book')
      end
    end

    context 'when metadata fetch fails' do
      let(:ol_client) { instance_double(OpenLibrary::Client) }

      before do
        allow(OpenLibrary::Client).to receive(:new).and_return(ol_client)
        allow(ol_client).to receive(:ia_identifier).and_return('test_id')
        allow(ol_client).to receive(:ia_metadata).and_return(nil)
      end

      it 'redirects with error' do
        get :browse_scans, params: { id: toc.id }

        expect(response).to redirect_to(toc)
        expect(flash[:error]).to eq('Unable to fetch scan metadata')
      end
    end
  end

  describe 'POST #mark_pages' do
    it 'saves marked pages and transitions to pages_marked status' do
      marked_urls = [
        'https://archive.org/download/test/page/n5.jpg',
        'https://archive.org/download/test/page/n6.jpg'
      ]

      post :mark_pages, params: { id: toc.id, marked_pages: marked_urls }

      toc.reload
      expect(toc.toc_page_urls).to eq(marked_urls.join("\n"))
      expect(toc.status).to eq('pages_marked')
      expect(toc.no_explicit_toc).to eq(false)
      expect(response).to redirect_to(toc)
      expect(flash[:notice]).to eq('TOC pages marked successfully')
    end

    it 'saves no_explicit_toc flag and transitions status' do
      post :mark_pages, params: { id: toc.id, no_explicit_toc: '1' }

      toc.reload
      expect(toc.no_explicit_toc).to eq(true)
      expect(toc.status).to eq('pages_marked')
      expect(response).to redirect_to(toc)
    end

    it 'requires either marked pages or no_explicit_toc' do
      post :mark_pages, params: { id: toc.id }

      expect(response).to redirect_to(browse_scans_toc_path(toc))
      expect(flash[:error]).to match(/Please mark at least one page/)
    end

    it 'handles save failure' do
      allow_any_instance_of(Toc).to receive(:save).and_return(false)

      post :mark_pages, params: {
        id: toc.id,
        marked_pages: ['https://archive.org/test.jpg']
      }

      expect(response).to redirect_to(browse_scans_toc_path(toc))
      expect(flash[:error]).to eq('Failed to save marked pages')
    end
  end

  describe '#parse_marked_pages' do
    it 'parses newline-separated URLs' do
      urls = "https://archive.org/page1.jpg\nhttps://archive.org/page2.jpg\nhttps://archive.org/page3.jpg"
      result = controller.send(:parse_marked_pages, urls)

      expect(result).to eq([
        'https://archive.org/page1.jpg',
        'https://archive.org/page2.jpg',
        'https://archive.org/page3.jpg'
      ])
    end

    it 'returns empty array for nil input' do
      result = controller.send(:parse_marked_pages, nil)
      expect(result).to eq([])
    end

    it 'returns empty array for blank input' do
      result = controller.send(:parse_marked_pages, '')
      expect(result).to eq([])
    end

    it 'strips whitespace and rejects blank lines' do
      urls = "https://archive.org/page1.jpg\n  \n  https://archive.org/page2.jpg  \n\n"
      result = controller.send(:parse_marked_pages, urls)

      expect(result).to eq([
        'https://archive.org/page1.jpg',
        'https://archive.org/page2.jpg'
      ])
    end
  end

  describe 'POST #do_ocr' do
    context 'with provided URLs' do
      it 'uses the provided URLs for OCR' do
        allow(controller).to receive(:valid?).and_return(true)
        allow(controller).to receive(:get_ocr_from_service).and_return('OCR result')

        post :do_ocr, params: { ocr_images: 'https://archive.org/test.jpg' }, xhr: true

        expect(controller).to have_received(:get_ocr_from_service).with('https://archive.org/test.jpg')
        expect(assigns(:results)).to include('OCR result')
      end
    end

    context 'without provided URLs but with marked TOC pages' do
      it 'falls back to using marked TOC pages' do
        toc_with_pages = Toc.create!(
          book_uri: 'http://openlibrary.org/books/OL123M',
          title: 'Test',
          toc_page_urls: "https://archive.org/page1.jpg\nhttps://archive.org/page2.jpg"
        )

        allow(controller).to receive(:valid?).and_return(true)
        allow(controller).to receive(:get_ocr_from_service).and_return('OCR result')

        post :do_ocr, params: { toc_id: toc_with_pages.id, ocr_images: '' }, xhr: true

        expect(controller).to have_received(:get_ocr_from_service).twice
        expect(assigns(:results)).to include('OCR result')
      end
    end

    context 'without URLs and without marked pages' do
      it 'processes empty list gracefully' do
        post :do_ocr, params: { ocr_images: '' }, xhr: true

        expect(assigns(:results)).to eq('')
      end
    end
  end
end
