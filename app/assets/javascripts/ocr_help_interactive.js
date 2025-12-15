// Interactive OCR help examples
$(document).ready(function() {
  if ($('.ocr-example-before').length === 0) return;

  // Add animation to show before/after transformation
  $('.ocr-example-before').on('click', function() {
    var $this = $(this);
    $this.addClass('highlight-pulse');
    setTimeout(function() {
      $('.ocr-example-after').addClass('highlight-pulse');
    }, 500);

    setTimeout(function() {
      $('.ocr-example-before, .ocr-example-after').removeClass('highlight-pulse');
    }, 2000);
  });

  // Add hover tooltips for specific OCR issues
  $('.code-example').each(function() {
    $(this).attr('title', I18n.t('help.contextual.ocr.click_to_highlight'));
    $(this).tooltip();
  });
});
