module TocsHelper
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
