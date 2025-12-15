// Initialize I18n object for JavaScript translations
var I18n = I18n || {};

I18n.t = function(key, options) {
  // This will be populated by Rails on page load
  // with translations from Rails.application.config.i18n
  return window.I18nTranslations && window.I18nTranslations[key]
    ? window.I18nTranslations[key]
    : key;
};

// Load I18n translations into JavaScript on page load
$(document).ready(function() {
  // Translations will be injected by layout
});
