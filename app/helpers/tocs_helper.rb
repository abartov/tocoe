module TocsHelper
  # Generate a sortable column header link
  # column: the database column to sort by
  # title: the display text for the header
  def sortable_column(column, title = nil)
    title ||= column.titleize
    direction = column == params[:sort] && params[:direction] == 'asc' ? 'desc' : 'asc'

    # Build CSS classes
    css_class = 'sortable'
    css_class += ' sorted' if column == params[:sort]

    # Add direction indicator if this column is currently sorted
    indicator = if column == params[:sort]
                  params[:direction] == 'asc' ? ' ↑' : ' ↓'
                else
                  ''
                end

    link_to "#{title}#{indicator}".html_safe,
            tocs_path(sort: column, direction: direction, status: params[:status], show_all: params[:show_all]),
            class: css_class
  end

  def filter_tab_style(is_active)
    base_style = 'padding: 0.5rem 1rem; border-radius: 20px; text-decoration: none; font-weight: 500; transition: all 0.2s; display: inline-block;'
    if is_active
      base_style + ' background: #667eea; color: white; border: 2px solid #667eea;'
    else
      base_style + ' background: white; color: #4a5568; border: 2px solid #e2e8f0;'
    end
  end

  def toc_markdown_to_html_preview(markdown)
    return '' if markdown.blank?

    html_lines = []

    markdown.split("\n").each do |line|
      next if line.strip.empty?

      # Match heading patterns
      if line =~ /^(\#{1,2})\s+(.+)$/
        level = $1.length
        content = $2.strip

        # Check if it's a section heading (ends with /)
        if content.end_with?('/')
          title = content.chomp('/').strip
          html_lines << "<h#{level} class='toc-section'>#{ERB::Util.html_escape(title)}</h#{level}>"
        else
          # Check if there's an author (contains ||)
          if content.include?('||')
            title, authors = content.split('||', 2)
            title = title.strip
            authors = authors.strip
            html_lines << "<h#{level} class='toc-entry'>"
            html_lines << "  #{ERB::Util.html_escape(title)}"
            html_lines << "  <span class='toc-author'>#{ERB::Util.html_escape(authors)}</span>"
            html_lines << "</h#{level}>"
          else
            # Just a title
            html_lines << "<h#{level} class='toc-entry'>#{ERB::Util.html_escape(content)}</h#{level}>"
          end
        end
      end
    end

    html_lines.join("\n").html_safe
  end
end
