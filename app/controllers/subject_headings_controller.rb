class SubjectHeadingsController < ApplicationController
  # GET /subject_headings
  # Browse and explore subject headings across all aboutnesses
  def index
    # Overall statistics
    @stats = {
      total_aboutnesses: Aboutness.count,
      verified_aboutnesses: Aboutness.verified.count,
      proposed_aboutnesses: Aboutness.proposed.count,
      unique_headings: Aboutness.distinct.count(:subject_heading_uri),
      lcsh_headings: Aboutness.where(source_name: 'LCSH').distinct.count(:subject_heading_uri),
      wikidata_headings: Aboutness.where(source_name: 'Wikidata').distinct.count(:subject_heading_uri)
    }

    # Latest aboutnesses added to the database (limit 10)
    @latest_aboutnesses = Aboutness.order(created_at: :desc)
                                   .limit(10)
                                   .includes(:embodiment)

    # Most frequently linked subject headings (limit 20)
    # Group by URI and label, count occurrences, sort by count descending
    @popular_headings = Aboutness.group(:subject_heading_uri, :subject_heading_label, :source_name)
                                 .select('subject_heading_uri, subject_heading_label, source_name, COUNT(*) as aboutness_count')
                                 .order('aboutness_count DESC')
                                 .limit(20)

    # Handle search query if present
    if params[:q].present?
      query = "%#{params[:q]}%"
      @search_results = Aboutness.where('subject_heading_label LIKE ?', query)
                                 .group(:subject_heading_uri, :subject_heading_label, :source_name)
                                 .select('subject_heading_uri, subject_heading_label, source_name, COUNT(*) as aboutness_count')
                                 .order('aboutness_count DESC')
                                 .limit(50)
    end
  end

  # GET /subject_headings/autocomplete
  # AJAX endpoint for autocomplete search
  def autocomplete
    query = params[:q]
    return render json: [] if query.blank?

    # Search for subject headings matching the query
    results = Aboutness.where('subject_heading_label LIKE ?', "%#{query}%")
                       .group(:subject_heading_uri, :subject_heading_label, :source_name)
                       .select('subject_heading_uri, subject_heading_label, source_name, COUNT(*) as aboutness_count')
                       .order('aboutness_count DESC')
                       .limit(10)

    # Format results for autocomplete
    formatted_results = results.map do |r|
      {
        uri: r.subject_heading_uri,
        label: r.subject_heading_label,
        source: r.source_name,
        count: r.aboutness_count
      }
    end

    render json: formatted_results
  end

  # GET /subject_headings/:id
  # Show details for a specific subject heading
  # The :id parameter should be a Base64-encoded version of the URI to avoid routing issues with slashes
  def show
    # Decode the URI from Base64-encoded parameter
    @subject_heading_uri = if params[:id].present?
                            begin
                              Base64.urlsafe_decode64(params[:id])
                            rescue ArgumentError
                              # Fallback to CGI unescape for backward compatibility
                              CGI.unescape(params[:id])
                            end
                          else
                            nil
                          end

    # Find all aboutnesses for this URI
    @aboutnesses = Aboutness.where(subject_heading_uri: @subject_heading_uri)
                           .includes(embodiment: { expression: { work: :creators } })
                           .order(created_at: :desc)

    # Get the label and source from the first aboutness
    if @aboutnesses.any?
      @subject_heading_label = @aboutnesses.first.subject_heading_label
      @source_name = @aboutnesses.first.source_name
    else
      # No aboutnesses found for this URI
      redirect_to subject_headings_path, alert: 'Subject heading not found.'
      return
    end

    # Count statistics
    @total_links = @aboutnesses.count
    @verified_links = @aboutnesses.verified.count
    @proposed_links = @aboutnesses.proposed.count

    # Get unique works linked to this subject heading
    @linked_works = @aboutnesses.map { |a| a.embodiment&.expression&.work }
                                .compact
                                .uniq
  end
end
