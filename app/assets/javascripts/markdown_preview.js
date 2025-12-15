// Live Markdown Preview for TOC Body help
$(document).ready(function() {
  if ($('#markdownPreviewInput').length === 0) return;

  // Function to parse and render markdown preview
  function updateMarkdownPreview() {
    var input = $('#markdownPreviewInput').val();
    var lines = input.split('\n');
    var html = '<ul class="markdown-preview-list">';

    lines.forEach(function(line) {
      if (line.trim() === '') return;

      var trimmed = line.trim();
      var indent = 0;
      var display = trimmed;
      var cssClass = '';

      // Detect line type
      if (trimmed.startsWith('## ')) {
        indent = 1;
        display = trimmed.substring(3);
        cssClass = 'nested-work';
      } else if (trimmed.startsWith('# ')) {
        display = trimmed.substring(2);
        cssClass = 'top-level-work';
      }

      // Check for section heading (trailing /)
      if (display.endsWith(' /')) {
        display = display.substring(0, display.length - 2);
        cssClass += ' section-heading';
      }

      // Check for author (||)
      if (display.includes(' || ')) {
        var parts = display.split(' || ');
        display = '<span class="work-title">' + parts[0] + '</span>' +
                  ' <span class="work-author">by ' + parts[1] + '</span>';
      }

      var indentStyle = 'margin-left: ' + (indent * 20) + 'px;';
      html += '<li class="' + cssClass + '" style="' + indentStyle + '">' + display + '</li>';
    });

    html += '</ul>';
    $('#markdownPreviewOutput').html(html);
  }

  // Update preview on input
  $('#markdownPreviewInput').on('input', updateMarkdownPreview);

  // Initial render
  updateMarkdownPreview();
});
