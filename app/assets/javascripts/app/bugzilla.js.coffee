#
# Methods for fetching and applying bug info from Bugzilla
#

bugzillaCache = []

applyBugzillaInfo = (node, info) ->
  $node = $(node)

  if info?
    status = info.status
    if ~['RESOLVED', 'VERIFIED'].indexOf status
      $node.addClass("resolved")
      status = info.resolution
    else
      $node.addClass("unresolved")

    text = info.summary
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
    id = $.trim($(node).text())
    if bugzillaCache[id]?
      applyBugzillaInfo(node, bugzillaCache[id])
    else
      bugIds.push(id) if $.inArray(id, bugIds) == -1

  return if bugIds.length == 0

  $.getJSON searchUrl, "bugids[]=" + bugIds.toString(), (data) ->
    hash = []
    for i in [1..data.length - 1]
      row = data[i]
      id  = row[0]
      hash[id.toString()] = summary: row[1], status: row[2], resolution: row[3]

    $('.bugzilla.fetch').each (i, node) ->
      id = $.trim($(node).text())
      if id in bugzillaCache
        info = bugzillaCache[id]
      else
        info = hash[id];
        bugzillaCache[id] = info if info?
      applyBugzillaInfo(node, info);
