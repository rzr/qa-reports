#
# Methods for fetching and applying bug info from Bugzilla
#

bugzillaCache = {}

applyBugzillaInfo = (node, info) ->
  $node = $(node)

  if info?
    status = info.status
    if status in ['RESOLVED', 'VERIFIED']
      $node.addClass("resolved")
      status = info.resolution
    else
      $node.addClass("unresolved")

    text = info.title
    if $node.closest('td.testcase_notes').length != 0
      $node.attr("title", "#{text} (#{status})")
    else if $node.hasClass("bugzilla_append")
      $node.after("<span> - #{text} (#{status})</span>");
    else
      $node.text(text);
      $node.attr("title", status);

  else
    $node.addClass("invalid")


  $node.removeClass("fetch")

@fetchBugzillaInfo = ->
  bugIds    = []
  searchUrl = "/fetch_bugzilla_data"

  links = $('.bugzilla.fetch')
  links.each (i, node) ->
    id = $.trim($(node).attr('data-id'))
    if id of bugzillaCache
      applyBugzillaInfo(node, bugzillaCache[id])
    else
      bugIds.push(id) unless id in bugIds

  return if bugIds.length == 0

  $.getJSON searchUrl, bugids: bugIds, (data) ->
    # Merge the new data to bugzillaCache and run recrsively again to eliminate
    # duplicated code used earlier
    bugzillaCache[id] = obj for id, obj of data
    fetchBugzillaInfo()
