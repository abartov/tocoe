module ContextualHelpHelper
  # Checks if contextual help should be shown for the current user
  #
  # @return [Boolean] true if user is signed in and has help enabled
  def show_contextual_help?
    current_user&.help_enabled == true
  end

  # Alias for show_contextual_help? for convenience
  #
  # @return [Boolean] true if user is signed in and has help enabled
  def help_enabled?
    current_user&.help_enabled == true
  end
end
