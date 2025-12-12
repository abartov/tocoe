module ApplicationHelper
  def breadcrumbs
    crumbs = []

    # Always start with Home
    crumbs << { name: t('common.navigation.home', default: 'Home'), path: root_path }

    # Determine breadcrumbs based on controller and action
    case controller_name
    when 'tocs'
      crumbs << { name: t('common.navigation.tocs', default: 'TOCs'), path: tocs_path }

      if action_name == 'show' && @toc
        crumbs << { name: @toc.title, path: nil }
      elsif action_name == 'edit' && @toc
        crumbs << { name: @toc.title, path: toc_path(@toc) }
        crumbs << { name: t('common.actions.edit', default: 'Edit'), path: nil }
      elsif action_name == 'browse_scans' && @toc
        crumbs << { name: @toc.title, path: toc_path(@toc) }
        crumbs << { name: t('tocs.browse_scans.title', default: 'Browse Scans'), path: nil }
      elsif action_name == 'new'
        crumbs << { name: t('tocs.new.title', book_title: @toc.title, authors: @authors.map{|a| a['name']}.join(','), default: 'New TOC'), path: nil }
      end

    when 'publications'
      if action_name == 'search'
        crumbs << { name: t('publications.search.title', default: 'Search Publications'), path: nil }
      end

    when 'aboutnesses'
      crumbs << { name: t('aboutnesses.title', default: 'Subject Headings'), path: nil }

    when 'help'
      crumbs << { name: t('help.title', default: 'Help'), path: nil }
    end

    crumbs
  end

  def render_breadcrumbs
    return '' if breadcrumbs.length <= 1

    content_tag(:nav, class: 'breadcrumb-nav', style: 'background: #f7fafc; padding: 0.75rem 2rem; margin: -2rem 0 2rem 0; border-bottom: 1px solid #e2e8f0;', 'aria-label': 'breadcrumb') do
      content_tag(:ol, class: 'breadcrumb', style: 'margin: 0; background: transparent; padding: 0;') do
        breadcrumbs.map.with_index do |(crumb), index|
          is_last = index == breadcrumbs.length - 1

          content_tag(:li, class: "breadcrumb-item #{'active' if is_last}", style: 'display: inline; color: #4a5568;') do
            if is_last || crumb[:path].nil?
              content_tag(:span, crumb[:name], style: 'color: #2d3748;')
            else
              link_to(crumb[:name], crumb[:path], style: 'color: #667eea; text-decoration: none;')
            end
          end
        end.join(' <span style="color: #a0aec0; margin: 0 0.5rem;">/</span> '.html_safe).html_safe
      end
    end
  end
end
