// Help system JavaScript
// Initializes Bootstrap 3 tooltips and popovers

$(document).ready(function() {
  // Initialize all Bootstrap tooltips
  $('[data-toggle="tooltip"]').tooltip({
    container: 'body', // Append to body to avoid positioning issues
    animation: true,
    delay: { show: 300, hide: 100 }
  });

  // Initialize all Bootstrap popovers
  $('[data-toggle="popover"]').popover({
    container: 'body',
    animation: true,
    html: true // Allow HTML content in popovers
  });

  // Auto-hide popovers when clicking elsewhere
  $('body').on('click', function (e) {
    $('[data-toggle="popover"]').each(function () {
      // Hide popover if click is outside the popover and outside the trigger
      if (!$(this).is(e.target) &&
          $(this).has(e.target).length === 0 &&
          $('.popover').has(e.target).length === 0) {
        $(this).popover('hide');
      }
    });
  });

  // Re-initialize tooltips after AJAX content loads
  $(document).on('ajaxComplete', function() {
    $('[data-toggle="tooltip"]').tooltip({
      container: 'body',
      animation: true,
      delay: { show: 300, hide: 100 }
    });
  });
});
