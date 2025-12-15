// Help Sidebar toggle functionality
$(document).ready(function() {
  // Initialize help sidebar state from localStorage
  $('.help-sidebar-collapsible').each(function() {
    var sidebar = $(this);
    var sidebarId = sidebar.attr('id');
    var storageKey = 'help_sidebar_' + sidebarId + '_collapsed';
    var isCollapsed = localStorage.getItem(storageKey) === 'true';

    if (isCollapsed) {
      sidebar.addClass('collapsed');
      sidebar.find('.help-sidebar-content').hide();
      sidebar.find('.help-toggle-text').text(I18n.t('help.contextual.common.show'));
      sidebar.find('.glyphicon-chevron-right').removeClass('glyphicon-chevron-right')
            .addClass('glyphicon-chevron-left');
    }
  });

  // Toggle sidebar on button click
  $('.help-sidebar-toggle').click(function() {
    var button = $(this);
    var sidebar = button.closest('.help-sidebar-collapsible');
    var sidebarId = sidebar.attr('id');
    var content = sidebar.find('.help-sidebar-content');
    var storageKey = 'help_sidebar_' + sidebarId + '_collapsed';

    sidebar.toggleClass('collapsed');
    content.slideToggle(300);

    var isCollapsed = sidebar.hasClass('collapsed');
    localStorage.setItem(storageKey, isCollapsed);

    // Update button text and icon
    var toggleText = button.find('.help-toggle-text');
    var icon = button.find('.glyphicon');

    if (isCollapsed) {
      toggleText.text(I18n.t('help.contextual.common.show'));
      icon.removeClass('glyphicon-chevron-right').addClass('glyphicon-chevron-left');
    } else {
      toggleText.text(I18n.t('help.contextual.common.hide'));
      icon.removeClass('glyphicon-chevron-left').addClass('glyphicon-chevron-right');
    }
  });
});
