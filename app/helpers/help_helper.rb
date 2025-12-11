module HelpHelper
  # Generates a Bootstrap 3 tooltip icon with help text
  #
  # @param text [String] The tooltip text to display
  # @param options [Hash] Optional configuration
  # @option options [String] :icon ('glyphicon-question-sign') The icon class to use
  # @option options [String] :placement ('top') Tooltip placement (top, bottom, left, right)
  # @option options [String] :trigger ('hover focus') Events that trigger the tooltip
  #
  # @return [String] HTML string for the tooltip icon
  #
  # @example
  #   = help_tooltip('Enter the OpenLibrary or Gutenberg book URL')
  #   = help_tooltip('Click to auto-match subjects', icon: 'glyphicon-info-sign', placement: 'right')
  def help_tooltip(text, options = {})
    icon = options[:icon] || 'glyphicon-question-sign'
    placement = options[:placement] || 'top'
    trigger = options[:trigger] || 'hover focus'

    content_tag(:i, '', class: "glyphicon #{icon} help-icon",
                'data-toggle' => 'tooltip',
                'data-placement' => placement,
                'data-trigger' => trigger,
                title: text)
  end

  # Generates a Bootstrap 3 popover icon with help title and content
  #
  # @param title [String] The popover title
  # @param content [String] The popover content (can include HTML)
  # @param options [Hash] Optional configuration
  # @option options [String] :icon ('glyphicon-info-sign') The icon class to use
  # @option options [String] :placement ('right') Popover placement (top, bottom, left, right)
  # @option options [String] :trigger ('hover focus') Events that trigger the popover
  #
  # @return [String] HTML string for the popover icon
  #
  # @example
  #   = help_popover('Markdown Format', 'Use # for titles, ## for nested items')
  #   = help_popover('OCR Help', '<p>Extract text from scanned pages</p>', placement: 'bottom')
  def help_popover(title, content, options = {})
    icon = options[:icon] || 'glyphicon-info-sign'
    placement = options[:placement] || 'right'
    trigger = options[:trigger] || 'hover focus'

    content_tag(:i, '', class: "glyphicon #{icon} help-icon",
                'data-toggle' => 'popover',
                'data-placement' => placement,
                'data-trigger' => trigger,
                title: title,
                'data-content' => content,
                'data-html' => 'true')
  end

  # Helper to determine if a nav link should be active
  #
  # @param path [String] The path to check against current page
  # @return [String] CSS class string for nav link
  #
  # @example
  #   = link_to 'Dashboard', root_path, class: nav_link_class(root_path)
  def nav_link_class(path)
    current_page?(path) ? 'nav-link active' : 'nav-link'
  end
end
