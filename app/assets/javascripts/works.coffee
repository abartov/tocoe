# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  # Ajax search on submit
  $('#works_search').submit( ->
    $.get(this.action, $(this).serialize(), null, 'script')
    false
  )
#  # Ajax search on keyup
#  $('#works_search input').keyup( ->
#    $.get($("#works_search").attr("action"), $("#works_search").serialize(), null, 'script')
#    false
#  )  
