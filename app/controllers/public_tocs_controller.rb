# Public (unauthenticated) controller for browsing verified TOCs
class PublicTocsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_toc, only: [:show, :download]

  # GET /browse
  # Public index of verified TOCs
  def index
    # Only show verified TOCs
    @tocs = Toc.where(status: :verified)

    # Apply sorting
    @tocs = apply_sorting(@tocs)
  end

  # GET /browse/:id
  # Public show page for individual verified TOC
  def show
    @manifestation = @toc.manifestation

    # Check if this is a Gutenberg book and fetch fulltext URL
    if @toc.source == 'gutenberg' || @toc.book_uri =~ %r{gutenberg\.org/ebooks/(\d+)}
      pg_book_id = $1
      gutendex_client = Gutendex::Client.new
      @fulltext_url = gutendex_client.preferred_fulltext_url(pg_book_id)
      @is_gutenberg = true
    else
      @is_gutenberg = false
    end
  end

  # GET /browse/:id/download?format=plaintext|markdown|json
  # Public download endpoint for verified TOCs
  def download
    format = params[:format] || 'plaintext'

    # Generate filename from TOC title (sanitized)
    base_filename = @toc.title.parameterize(separator: '_')

    case format
    when 'plaintext'
      content = helpers.export_toc_as_plaintext(@toc)
      filename = "#{base_filename}.txt"
      content_type = 'text/plain'
    when 'markdown'
      content = helpers.export_toc_as_markdown(@toc)
      filename = "#{base_filename}.md"
      content_type = 'text/markdown'
    when 'json'
      content = helpers.export_toc_as_json(@toc)
      filename = "#{base_filename}.json"
      content_type = 'application/json'
    else
      # Default to plaintext if unknown format
      content = helpers.export_toc_as_plaintext(@toc)
      filename = "#{base_filename}.txt"
      content_type = 'text/plain'
    end

    send_data content,
              filename: filename,
              type: content_type,
              disposition: 'attachment'
  end

  private

  # Set TOC from params (only verified TOCs)
  def set_toc
    @toc = Toc.verified.find(params[:id])
  end

  # Apply sorting to TOCs collection based on params
  # Simplified version for public view (only title and created_at)
  def apply_sorting(tocs)
    # Whitelist of allowed sort columns for public view
    allowed_columns = %w[title created_at]
    sort_column = params[:sort].presence_in(allowed_columns)
    sort_direction = params[:direction] == 'desc' ? :desc : :asc

    if sort_column
      tocs.order(sort_column => sort_direction)
    else
      # Default sorting: created_at desc (show newest first)
      tocs.order(created_at: :desc)
    end
  end
end
