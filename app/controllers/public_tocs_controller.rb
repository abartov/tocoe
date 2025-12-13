# Public (unauthenticated) controller for browsing verified TOCs
class PublicTocsController < ApplicationController
  skip_before_action :authenticate_user!

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
    # Only allow access to verified TOCs
    @toc = Toc.verified.find(params[:id])
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

  private

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
