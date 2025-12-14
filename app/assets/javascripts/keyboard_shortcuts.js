// Global keyboard shortcuts for ToCoE
// Handles navigation and action shortcuts across the application

(function() {
  'use strict';

  var KeyboardShortcuts = {
    // Track if we're in a "g" sequence (for go shortcuts)
    inGoSequence: false,
    goSequenceTimeout: null,

    // Initialize keyboard shortcuts
    init: function() {
      this.bindGlobalShortcuts();
      this.bindContextShortcuts();
      this.createShortcutsModal();
    },

    // Check if we should ignore shortcuts (e.g., when typing in input)
    shouldIgnoreShortcut: function(e) {
      var target = $(e.target);
      return target.is('input, textarea, select') ||
             target.attr('contenteditable') === 'true';
    },

    // Bind global shortcuts that work everywhere
    bindGlobalShortcuts: function() {
      var self = this;

      $(document).on('keydown', function(e) {
        // Ignore if typing in input fields
        if (self.shouldIgnoreShortcut(e)) {
          return;
        }

        var key = String.fromCharCode(e.which).toLowerCase();

        // Handle "g" sequence for navigation
        if (key === 'g' && !e.ctrlKey && !e.metaKey && !e.altKey) {
          e.preventDefault();
          self.startGoSequence();
          return;
        }

        // If we're in a "g" sequence, handle the second key
        if (self.inGoSequence) {
          e.preventDefault();
          self.handleGoSequence(key);
          return;
        }

        // Handle standalone shortcuts
        switch(key) {
          case '?':
            // Show shortcuts help (? is Shift+/)
            if (e.shiftKey) {
              e.preventDefault();
              self.showShortcutsModal();
            }
            break;

          case '/':
            // Focus search bar or go to search page
            e.preventDefault();
            self.focusOrGoToSearch();
            break;

          case 's':
            // Go to search page (if not Cmd/Ctrl+S)
            if (!e.ctrlKey && !e.metaKey) {
              e.preventDefault();
              self.focusOrGoToSearch();
            }
            break;

          case 'h':
            // Go to help page
            if (!e.ctrlKey && !e.metaKey && !e.altKey) {
              e.preventDefault();
              window.location.href = '/help';
            }
            break;
        }
      });
    },

    // Bind context-specific shortcuts
    bindContextShortcuts: function() {
      var self = this;

      $(document).on('keydown', function(e) {
        if (self.shouldIgnoreShortcut(e)) {
          return;
        }

        var key = String.fromCharCode(e.which).toLowerCase();

        // TOC list page shortcuts
        if ($('body').hasClass('tocs') && $('body').hasClass('index')) {
          if (key === 'n' && !e.ctrlKey && !e.metaKey && !e.altKey) {
            e.preventDefault();
            // Find and click the "New TOC" button/link
            var newTocLink = $('a[href="/tocs/new"]').first();
            if (newTocLink.length > 0) {
              window.location.href = newTocLink.attr('href');
            }
          }
        }

        // TOC show page shortcuts
        if ($('body').hasClass('tocs') && $('body').hasClass('show')) {
          if (key === 'e' && !e.ctrlKey && !e.metaKey && !e.altKey) {
            e.preventDefault();
            // Find and click the Edit button
            var editLink = $('a[href^="/tocs/"][href$="/edit"]').first();
            if (editLink.length > 0) {
              window.location.href = editLink.attr('href');
            }
          }
        }

        // TOC form page shortcuts
        if ($('body').hasClass('tocs') && ($('body').hasClass('edit') || $('body').hasClass('new'))) {
          // Cmd/Ctrl+S to save form
          if (key === 's' && (e.ctrlKey || e.metaKey)) {
            e.preventDefault();
            var submitButton = $('.toc-form-container form input[type="submit"]').first();
            if (submitButton.length > 0) {
              submitButton.click();
            }
          }
        }
      });
    },

    // Start "g" sequence timer
    startGoSequence: function() {
      var self = this;
      this.inGoSequence = true;

      // Show visual feedback
      this.showGoSequenceFeedback();

      // Clear any existing timeout
      if (this.goSequenceTimeout) {
        clearTimeout(this.goSequenceTimeout);
      }

      // Reset after 1.5 seconds
      this.goSequenceTimeout = setTimeout(function() {
        self.endGoSequence();
      }, 1500);
    },

    // End "g" sequence
    endGoSequence: function() {
      this.inGoSequence = false;
      this.hideGoSequenceFeedback();
    },

    // Handle the second key in "g" sequence
    handleGoSequence: function(key) {
      this.endGoSequence();

      switch(key) {
        case 'd':
          window.location.href = '/';
          break;
        case 't':
          window.location.href = '/tocs';
          break;
        case 's':
          window.location.href = '/publications/search';
          break;
        case 'h':
          window.location.href = '/help';
          break;
        case 'a':
          window.location.href = '/dashboard/aboutness';
          break;
      }
    },

    // Focus search bar if on page, otherwise go to search page
    focusOrGoToSearch: function() {
      var searchInput = $('.navbar-search-input').first();
      if (searchInput.length > 0 && searchInput.is(':visible')) {
        searchInput.focus();
      } else {
        window.location.href = '/publications/search';
      }
    },

    // Show visual feedback for "g" sequence
    showGoSequenceFeedback: function() {
      var feedback = $('<div>')
        .attr('id', 'go-sequence-feedback')
        .css({
          'position': 'fixed',
          'bottom': '20px',
          'right': '20px',
          'background': 'rgba(0, 0, 0, 0.8)',
          'color': '#fff',
          'padding': '10px 20px',
          'border-radius': '4px',
          'font-family': 'monospace',
          'font-size': '14px',
          'z-index': 9999
        })
        .text('g_');

      $('body').append(feedback);
    },

    // Hide "g" sequence feedback
    hideGoSequenceFeedback: function() {
      $('#go-sequence-feedback').remove();
    },

    // Create the shortcuts help modal
    createShortcutsModal: function() {
      var modalHtml =
        '<div id="keyboard-shortcuts-modal" class="modal fade" tabindex="-1" role="dialog">' +
          '<div class="modal-dialog" role="document">' +
            '<div class="modal-content">' +
              '<div class="modal-header">' +
                '<button type="button" class="close" data-dismiss="modal" aria-label="Close">' +
                  '<span aria-hidden="true">&times;</span>' +
                '</button>' +
                '<h4 class="modal-title">Keyboard Shortcuts</h4>' +
              '</div>' +
              '<div class="modal-body">' +
                '<div class="row">' +
                  '<div class="col-md-6">' +
                    '<h5>Global Shortcuts</h5>' +
                    '<table class="table table-condensed">' +
                      '<tbody>' +
                        '<tr><td><kbd>?</kbd></td><td>Show this help</td></tr>' +
                        '<tr><td><kbd>/</kbd> or <kbd>s</kbd></td><td>Focus search / Go to search</td></tr>' +
                        '<tr><td><kbd>g</kbd> <kbd>d</kbd></td><td>Go to Dashboard</td></tr>' +
                        '<tr><td><kbd>g</kbd> <kbd>t</kbd></td><td>Go to TOCs</td></tr>' +
                        '<tr><td><kbd>g</kbd> <kbd>s</kbd></td><td>Go to Search</td></tr>' +
                        '<tr><td><kbd>g</kbd> <kbd>h</kbd></td><td>Go to Help</td></tr>' +
                        '<tr><td><kbd>g</kbd> <kbd>a</kbd></td><td>Go to Subject Headings</td></tr>' +
                        '<tr><td><kbd>h</kbd></td><td>Go to Help</td></tr>' +
                      '</tbody>' +
                    '</table>' +
                  '</div>' +
                  '<div class="col-md-6">' +
                    '<h5>Context-Specific Shortcuts</h5>' +
                    '<table class="table table-condensed">' +
                      '<tbody>' +
                        '<tr><td colspan="2"><strong>TOC List Page</strong></td></tr>' +
                        '<tr><td><kbd>n</kbd></td><td>New TOC</td></tr>' +
                        '<tr><td colspan="2"><strong>TOC Show Page</strong></td></tr>' +
                        '<tr><td><kbd>e</kbd></td><td>Edit TOC</td></tr>' +
                        '<tr><td colspan="2"><strong>TOC Form</strong></td></tr>' +
                        '<tr><td><kbd>Alt</kbd>+<kbd>1-4</kbd></td><td>Switch tabs</td></tr>' +
                        '<tr><td><kbd>Cmd/Ctrl</kbd>+<kbd>S</kbd></td><td>Save form</td></tr>' +
                      '</tbody>' +
                    '</table>' +
                  '</div>' +
                '</div>' +
                '<div class="alert alert-info" style="margin-top: 20px; margin-bottom: 0;">' +
                  '<small><strong>Tip:</strong> Shortcuts are disabled when typing in text fields.</small>' +
                '</div>' +
              '</div>' +
              '<div class="modal-footer">' +
                '<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>' +
              '</div>' +
            '</div>' +
          '</div>' +
        '</div>';

      // Remove existing modal if present
      $('#keyboard-shortcuts-modal').remove();

      // Add modal to body
      $('body').append(modalHtml);
    },

    // Show the shortcuts modal
    showShortcutsModal: function() {
      $('#keyboard-shortcuts-modal').modal('show');
    }
  };

  // Initialize on document ready and after turbolinks load
  $(document).ready(function() {
    KeyboardShortcuts.init();
  });

  // Re-initialize after turbolinks navigates to new page
  $(document).on('turbolinks:load', function() {
    KeyboardShortcuts.init();
  });

  // Clean up before page cache (turbolinks)
  $(document).on('turbolinks:before-cache', function() {
    $('#keyboard-shortcuts-modal').remove();
    $('#go-sequence-feedback').remove();
  });

})();
