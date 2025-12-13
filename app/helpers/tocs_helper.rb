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

  # Format TOC body for compact preview in index (first few entries)
  def format_toc_preview(markdown, max_entries: 3)
    return '' if markdown.blank?

    entries = []
    entry_count = 0

    markdown.split("\n").each do |line|
      next if line.strip.empty?
      break if entry_count >= max_entries

      # Match heading patterns
      if line =~ /^(\#{1,2})\s+(.+)$/
        level = $1.length
        content = $2.strip

        # Skip section headings (end with /)
        next if content.end_with?('/')

        # Parse title and author
        if content.include?('||')
          title, authors = content.split('||', 2)
          entries << "#{title.strip} — #{authors.strip}"
        else
          entries << content
        end

        entry_count += 1
      end
    end

    result = entries.join(' • ')

    # Add ellipsis if there are more entries
    total_lines = markdown.split("\n").reject { |l| l.strip.empty? || l.strip.end_with?('/') }.count
    result += ' …' if total_lines > max_entries

    result
  end

  # Format status badge with icon
  def status_badge_with_icon(status)
    icons = {
      'empty' => '📝',
      'pages_marked' => '📑',
      'transcribed' => '📄',
      'verified' => '✅',
      'error' => '❌'
    }

    icon = icons[status.to_s] || '📋'
    "#{icon} #{status.to_s.titleize}".html_safe
  end

  # Export TOC as plaintext
  def export_toc_as_plaintext(toc)
    lines = []

    # Header
    lines << toc.title
    lines << "=" * toc.title.length
    lines << ""

    # Metadata
    lines << "Source: #{toc.book_uri}" if toc.book_uri.present?
    if toc.authors.any?
      lines << "Authors: #{toc.authors.map(&:name).join(', ')}"
    end
    lines << "Status: #{toc.status.to_s.titleize}"
    lines << ""
    lines << "-" * 60
    lines << ""

    # TOC entries
    if toc.toc_body.present?
      toc.toc_body.split("\n").each do |line|
        next if line.strip.empty?

        # Match heading patterns
        if line =~ /^(\#{1,2})\s+(.+)$/
          level = $1.length
          content = $2.strip

          # Indentation based on level
          indent = "  " * (level - 1)

          # Check if it's a section heading (ends with /)
          if content.end_with?('/')
            title = content.chomp('/').strip
            lines << "#{indent}#{title}"
          else
            # Check if there's an author (contains ||)
            if content.include?('||')
              title, authors = content.split('||', 2)
              lines << "#{indent}#{title.strip} (#{authors.strip})"
            else
              lines << "#{indent}#{content}"
            end
          end
        end
      end
    else
      lines << "(No table of contents has been transcribed yet)"
    end

    lines.join("\n")
  end

  # Export TOC as markdown with metadata
  def export_toc_as_markdown(toc)
    lines = []

    # Title and metadata
    lines << "# #{toc.title}"
    lines << ""
    lines << "**Source:** #{toc.book_uri}" if toc.book_uri.present?
    if toc.authors.any?
      lines << "**Authors:** #{toc.authors.map(&:name).join(', ')}"
    end
    lines << "**Status:** #{toc.status.to_s.titleize}"
    lines << ""
    lines << "---"
    lines << ""

    # TOC body
    if toc.toc_body.present?
      lines << "## Table of Contents"
      lines << ""
      lines << toc.toc_body
    else
      lines << "(No table of contents has been transcribed yet)"
    end

    # Footer with metadata
    lines << ""
    lines << "---"
    lines << ""
    lines << "_Generated by ToCoE (Table of Contents of Everything)_"
    lines << "_Licensed under CC0 (Public Domain)_"

    lines.join("\n")
  end

  # Export TOC as JSON
  def export_toc_as_json(toc)
    entries = []

    if toc.toc_body.present?
      sequence = 0
      toc.toc_body.split("\n").each do |line|
        next if line.strip.empty?

        # Match heading patterns
        if line =~ /^(\#{1,2})\s+(.+)$/
          level = $1.length
          content = $2.strip

          entry = {
            sequence_number: sequence += 1,
            level: level
          }

          # Check if it's a section heading (ends with /)
          if content.end_with?('/')
            entry[:title] = content.chomp('/').strip
            entry[:is_section_heading] = true
          else
            # Check if there's an author (contains ||)
            if content.include?('||')
              title, authors = content.split('||', 2)
              entry[:title] = title.strip
              entry[:authors] = authors.strip.split(/\s*;\s*/)
            else
              entry[:title] = content
            end
            entry[:is_section_heading] = false
          end

          entries << entry
        end
      end
    end

    {
      toc: {
        id: toc.id,
        title: toc.title,
        book_uri: toc.book_uri,
        source: toc.source,
        status: toc.status,
        authors: toc.authors.map { |author|
          {
            name: author.name,
            openlibrary_id: author.openlibrary_id,
            viaf_id: author.viaf_id,
            wikidata_q: author.wikidata_q,
            loc_id: author.loc_id,
            gutenberg_id: author.gutenberg_id
          }.compact
        },
        entries: entries,
        metadata: {
          created_at: toc.created_at,
          updated_at: toc.updated_at,
          contributor: toc.contributor&.email,
          reviewer: toc.reviewer&.email
        }.compact
      }
    }.to_json
  end
end
