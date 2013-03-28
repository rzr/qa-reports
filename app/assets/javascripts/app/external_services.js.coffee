#
# Methods for fetching and applying info from external services such as
# Bugzilla. Backend will identify from which service to fetch data based
# on the given IDs and their prefixes.
#
# The backend will currently return JSON data with the item ID given as the
# key, and as value an object with following fields:
#   uri, status, resolution, title, id
#

infoCache = {}

applyExternalInfo = (node, info) ->
  $node = $(node)

  if info?
    status = info.status

    # Currently only Bugzilla info items have status
    if status?
      if status in ['RESOLVED', 'VERIFIED']
        $node.addClass("resolved")
        status = info.resolution
      else
        $node.addClass("unresolved")

    text = info.title
    # Also title and status/resolution are available for Bugzilla only
    if text? and status?
      if $node.closest('td.testcase_notes').length != 0
        $node.attr("title", "#{text} (#{status})")
      else if $node.hasClass("ext_service_append")
        $node.after("<span> - #{text} (#{status})</span>");
      else
        $node.text(text);
        $node.attr("title", status);

    # TODO: plain links

  else
    $node.addClass("invalid")


  $node.removeClass("fetch")

@fetchExternalInfo = ->
  ids       = []
  searchUrl = "/fetch_external_data"

  links = $('.ext_service.fetch')
  links.each (i, node) ->
    id = $.trim($(node).attr('data-id'))
    if id of infoCache
      applyExternalInfo(node, infoCache[id])
    else
      ids.push(id) unless id in ids

  return if ids.length == 0

  $.getJSON searchUrl, ids: ids, (data) ->
    # Merge the new data to infoCache and run recrsively again to eliminate
    # duplicated code used earlier
    infoCache[id] = obj for id, obj of data
    fetchExternalInfo()
