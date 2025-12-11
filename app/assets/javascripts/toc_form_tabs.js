// TOC Form Tab State Management
// Handles tab switching, state persistence, and error handling

$(document).ready(function() {
  // Only run on pages with the TOC form
  if ($('.toc-form-container').length === 0) {
    return;
  }

  // Tab state management with localStorage
  var TAB_STORAGE_KEY = 'tocFormLastTab';

  // Restore last active tab from localStorage (only if no errors)
  if ($('#error_explanation').length === 0) {
    var lastTab = localStorage.getItem(TAB_STORAGE_KEY);
    if (lastTab) {
      var tabLink = $('a[href="' + lastTab + '"]');
      if (tabLink.length > 0) {
        tabLink.tab('show');
      }
    }
  }

  // Save active tab to localStorage when user switches tabs
  $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    var activeTab = $(e.target).attr('href');
    localStorage.setItem(TAB_STORAGE_KEY, activeTab);
  });

  // Handle form validation errors: switch to first tab with errors
  if ($('#error_explanation').length > 0) {
    // Determine which tab has errors based on field names
    var errorMessages = $('#error_explanation li').map(function() {
      return $(this).text();
    }).get();

    var hasBasicInfoError = errorMessages.some(function(msg) {
      return msg.includes('Book uri') || msg.includes('Title') || msg.includes('Comments');
    });

    var hasTocBodyError = errorMessages.some(function(msg) {
      return msg.includes('Toc body');
    });

    // Switch to the appropriate tab
    if (hasBasicInfoError) {
      $('a[href="#basic-info"]').tab('show');
      // Add error indicator to tab
      $('a[href="#basic-info"]').addClass('error-badge');
    } else if (hasTocBodyError) {
      $('a[href="#toc-body"]').tab('show');
      $('a[href="#toc-body"]').addClass('error-badge');
    }

    // Scroll to error explanation
    $('html, body').animate({
      scrollTop: $('#error_explanation').offset().top - 100
    }, 500);
  }

  // Show count of imported subjects as badge on Subjects tab
  // (Already implemented in the main form template via HAML)

  // Keyboard shortcuts for tab navigation (optional enhancement)
  $(document).on('keydown', function(e) {
    // Only if form is in focus and no input/textarea is focused
    if ($('.toc-form-container').length > 0 &&
        !$(e.target).is('input, textarea, select')) {

      // Alt+1 = Basic Info, Alt+2 = TOC Body, Alt+3 = Subjects, Alt+4 = OCR
      if (e.altKey) {
        var tabIndex = null;
        switch(e.which) {
          case 49: tabIndex = 0; break; // Alt+1
          case 50: tabIndex = 1; break; // Alt+2
          case 51: tabIndex = 2; break; // Alt+3
          case 52: tabIndex = 3; break; // Alt+4
        }

        if (tabIndex !== null) {
          var tabs = $('.nav-tabs li a');
          if (tabs[tabIndex]) {
            e.preventDefault();
            $(tabs[tabIndex]).tab('show');
          }
        }
      }
    }
  });

  // Auto-scroll to active tab link when switching (helpful for mobile)
  $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    var $target = $(e.target);
    var $tabContainer = $target.closest('.nav-tabs');

    // Scroll tab into view if it's outside viewport
    if ($tabContainer.length > 0) {
      var containerOffset = $tabContainer.offset().left;
      var targetOffset = $target.offset().left;
      var targetWidth = $target.outerWidth();
      var containerWidth = $tabContainer.width();

      if (targetOffset < containerOffset ||
          targetOffset + targetWidth > containerOffset + containerWidth) {
        $tabContainer.animate({
          scrollLeft: $tabContainer.scrollLeft() + targetOffset - containerOffset - 20
        }, 300);
      }
    }
  });

  // Warn user before leaving if form is dirty (has unsaved changes)
  var formChanged = false;
  $('.toc-form-container form').on('change', 'input, textarea, select', function() {
    formChanged = true;
  });

  $('.toc-form-container form').on('submit', function() {
    formChanged = false; // Clear flag on submit
  });

  $(window).on('beforeunload', function() {
    if (formChanged) {
      return 'You have unsaved changes. Are you sure you want to leave?';
    }
  });
});
