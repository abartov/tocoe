// ============================================================================
// Person Matcher Component JavaScript
// ============================================================================
// Handles the person matcher modal functionality including:
// - Searching across all authority sources
// - Expanding/collapsing result details
// - Matching a person to a target object
// ============================================================================

(function() {
  'use strict';

  // Person Matcher class
  var PersonMatcher = {
    // Configuration
    modal: null,
    config: null,
    currentQuery: '',
    currentCandidates: [],

    // Initialize the person matcher
    init: function() {
      this.modal = $('#person-matcher-modal');
      if (this.modal.length === 0) {
        return; // Modal not on page
      }

      this.bindEvents();
    },

    // Open the modal and perform initial search
    open: function(targetType, targetId, nameQuery, candidates) {
      this.config = {
        targetType: targetType,
        targetId: targetId
      };
      this.currentQuery = nameQuery || '';
      this.currentCandidates = candidates || [];

      // Update modal data attributes
      this.modal.attr('data-target-type', targetType);
      this.modal.attr('data-target-id', targetId);

      // Update query display
      $('#person-matcher-query-display').text(this.currentQuery);

      // Show modal
      this.modal.modal('show');

      // Perform initial search
      if (this.currentQuery) {
        this.searchAll();
      }
    },

    // Bind event handlers
    bindEvents: function() {
      var self = this;

      // Refine search button
      $('#person-matcher-refine-search').on('click', function() {
        self.promptRefineSearch();
      });

      // Clear all button
      $('#person-matcher-clear-all').on('click', function() {
        self.clearResults();
      });

      // Create new person button
      $('#person-matcher-create-new').on('click', function() {
        self.createNewPerson();
      });

      // Delegate expand/collapse and match buttons (dynamically created)
      this.modal.on('click', '.expand-toggle', function() {
        self.toggleDetails($(this));
      });

      this.modal.on('click', '.match-button', function() {
        self.matchPerson($(this));
      });
    },

    // Search all authority sources
    searchAll: function() {
      var self = this;

      // Show loading state
      $('.person-matcher-loading').show();
      $('.person-matcher-results-grid').hide();

      // AJAX call to search all sources
      $.ajax({
        url: '/people/search_all',
        type: 'POST',
        dataType: 'json',
        data: {
          query: this.currentQuery,
          candidates: this.currentCandidates
        },
        beforeSend: function(xhr) {
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
        },
        success: function(data) {
          self.renderResults(data);
        },
        error: function() {
          self.showError('Search failed. Please try again.');
        },
        complete: function() {
          $('.person-matcher-loading').hide();
          $('.person-matcher-results-grid').show();
        }
      });
    },

    // Render search results
    renderResults: function(data) {
      var self = this;

      // Render each source
      ['database', 'viaf', 'wikidata', 'loc'].forEach(function(source) {
        var results = data[source] || [];
        self.renderSourceResults(source, results);
      });
    },

    // Render results for a specific source
    renderSourceResults: function(source, results) {
      var columnResults = $('.column-results[data-source="' + source + '"]');
      var countElement = $('.count-number[data-source="' + source + '"]');

      // Update count
      countElement.text(results.length);

      // Clear existing results
      columnResults.empty();

      if (results.length === 0) {
        columnResults.html('<p class="person-matcher-no-results">No results found</p>');
        return;
      }

      // Render each result
      results.forEach(function(result) {
        var card = this.createResultCard(result);
        columnResults.append(card);
      }.bind(this));
    },

    // Create a result card element
    createResultCard: function(result) {
      var card = $('<div>').addClass('person-matcher-result-card');

      // Name
      var name = $('<h4>').addClass('result-name').text(result.label);
      card.append(name);

      // Badges
      var badges = $('<div>').addClass('result-badges');
      if (result.is_candidate) {
        badges.append($('<span>').addClass('badge badge-candidate').text('⭐ Likely in context'));
      }
      if (result.in_database) {
        badges.append($('<span>').addClass('badge badge-in-db').text('📚 In DB'));
      }
      if (badges.children().length > 0) {
        card.append(badges);
      }

      // Info (dates, country)
      var info = [];
      if (result.dates) info.push(result.dates);
      if (result.country) info.push(result.country);
      if (result.description) info.push(result.description);

      if (info.length > 0) {
        var infoText = $('<p>').addClass('result-info').text(info.join(' • '));
        card.append(infoText);
      }

      // Actions
      var actions = $('<div>').addClass('result-actions');

      var expandToggle = $('<button>')
        .addClass('expand-toggle')
        .attr('type', 'button')
        .text('Show more details')
        .data('source', result.source)
        .data('id', result.id);
      actions.append(expandToggle);

      var matchButton = $('<button>')
        .addClass('match-button btn btn-primary btn-sm')
        .attr('type', 'button')
        .text('Match!')
        .data('source', result.source)
        .data('id', result.id)
        .data('person-id', result.person_id);
      actions.append(matchButton);

      card.append(actions);

      // Details container (hidden initially)
      var details = $('<div>').addClass('result-details').hide();
      card.append(details);

      return card;
    },

    // Toggle details expansion
    toggleDetails: function($button) {
      var $details = $button.siblings('.result-details');
      var isExpanded = $details.is(':visible');

      if (isExpanded) {
        // Collapse
        $details.slideUp(200);
        $button.text('Show more details').removeClass('expanded');
      } else {
        // Expand and load details if not already loaded
        if ($details.children().length === 0) {
          this.loadDetails($button, $details);
        } else {
          $details.slideDown(200);
          $button.text('Hide details').addClass('expanded');
        }
      }
    },

    // Load detailed information via AJAX
    loadDetails: function($button, $details) {
      var source = $button.data('source');
      var id = $button.data('id');

      $details.html('<p class="person-matcher-loading-details">Loading details...</p>').show();
      $button.text('Loading...').addClass('expanded');

      $.ajax({
        url: '/people/fetch_details',
        type: 'GET',
        dataType: 'json',
        data: {
          source: source,
          id: id
        },
        success: function(data) {
          var html = this.formatDetails(data);
          $details.html(html).slideDown(200);
          $button.text('Hide details');
        }.bind(this),
        error: function() {
          $details.html('<p class="text-danger">Failed to load details</p>');
          $button.text('Show more details').removeClass('expanded');
        }
      });
    },

    // Format details data into HTML
    formatDetails: function(data) {
      var dl = $('<dl>');

      // Helper function to add detail row
      function addDetail(label, value) {
        if (value) {
          dl.append($('<dt>').text(label));
          dl.append($('<dd>').html(value));
        }
      }

      // Add various details based on what's available
      addDetail('Full Name', data.full_name);
      addDetail('Dates', data.dates);
      addDetail('Country', data.country);
      addDetail('Title', data.title);
      addDetail('Affiliation', data.affiliation);

      if (data.occupations && data.occupations.length > 0) {
        addDetail('Occupations', data.occupations.join(', '));
      }

      if (data.notable_works && data.notable_works.length > 0) {
        addDetail('Notable Works', data.notable_works.join(', '));
      }

      if (data.birth_date || data.death_date) {
        var dates = [];
        if (data.birth_date) dates.push('Born: ' + data.birth_date);
        if (data.death_date) dates.push('Died: ' + data.death_date);
        addDetail('Dates', dates.join('<br>'));
      }

      // Authority IDs
      if (data.authority_ids) {
        var ids = [];
        if (data.authority_ids.viaf) ids.push('VIAF: ' + data.authority_ids.viaf);
        if (data.authority_ids.wikidata) ids.push('Wikidata: Q' + data.authority_ids.wikidata);
        if (data.authority_ids.loc) ids.push('LoC: ' + data.authority_ids.loc);
        if (data.authority_ids.isni) ids.push('ISNI: ' + data.authority_ids.isni);

        if (ids.length > 0) {
          addDetail('Authority IDs', ids.join('<br>'));
        }
      }

      // Source-specific details
      if (data.viaf_id) {
        addDetail('VIAF ID', data.viaf_id);
      }
      if (data.wikidata_id) {
        addDetail('Wikidata ID', data.wikidata_id);
      }
      if (data.loc_id) {
        addDetail('LoC ID', data.loc_id);
      }

      return dl;
    },

    // Match a person to the target object
    matchPerson: function($button) {
      var source = $button.data('source');
      var externalId = $button.data('id');
      var personId = $button.data('person-id');

      // Disable button during request
      $button.prop('disabled', true).text('Matching...');

      $.ajax({
        url: '/people/match',
        type: 'POST',
        dataType: 'json',
        data: {
          target_type: this.config.targetType,
          target_id: this.config.targetId,
          source: source,
          external_id: externalId,
          person_id: personId
        },
        beforeSend: function(xhr) {
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
        },
        success: function(data) {
          if (data.success) {
            this.showSuccess();
            // Close modal after a short delay
            setTimeout(function() {
              this.modal.modal('hide');
              // Reload page to show updated associations
              location.reload();
            }.bind(this), 1500);
          } else {
            this.showError(data.error || 'Failed to create association');
            $button.prop('disabled', false).text('Match!');
          }
        }.bind(this),
        error: function() {
          this.showError('Failed to create association. Please try again.');
          $button.prop('disabled', false).text('Match!');
        }.bind(this)
      });
    },

    // Prompt user to refine search
    promptRefineSearch: function() {
      var newQuery = prompt('Enter new search query:', this.currentQuery);
      if (newQuery && newQuery !== this.currentQuery) {
        this.currentQuery = newQuery;
        $('#person-matcher-query-display').text(newQuery);
        this.searchAll();
      }
    },

    // Clear all results
    clearResults: function() {
      $('.column-results').empty();
      $('.count-number').text('0');
    },

    // Create a new person manually
    createNewPerson: function() {
      // Open the new person form in a new tab with the query pre-filled
      var url = '/people/new?name=' + encodeURIComponent(this.currentQuery);
      window.open(url, '_blank');
    },

    // Show success message
    showSuccess: function() {
      $('.person-matcher-results-container').html(
        '<div class="person-matcher-success">' +
        '<div class="success-icon">✓</div>' +
        '<p class="success-message">Successfully matched!</p>' +
        '</div>'
      );
    },

    // Show error message
    showError: function(message) {
      alert('Error: ' + message);
    }
  };

  // Initialize on document ready
  $(document).on('turbolinks:load', function() {
    PersonMatcher.init();
  });

  // Expose PersonMatcher globally for programmatic access
  window.PersonMatcher = PersonMatcher;

})();
