
bugzillaCache = []

activateSuggestionLinks = (target) ->
  $(target).each (i, node) ->
    $node = $(node)
    $node.find(".suggestions a").each (i, a) ->
      target = $node.find("input")
      $(a).data("target", target).click applySuggestion

applySuggestion = ->
  $this = $(this)
  $this.data("target").val $this.text()
  false

capitalize = (s) ->
  s.charAt(0).toUpperCase() + s.substr(1).toLowerCase()

toTitlecase = (s) ->
  s.replace /\w\S*/g, capitalize

htmlEscape = (s) ->
  s = s.replace("&", "&amp;")
  s = s.replace("<", "&lt;")
  s = s.replace(">", "&gt;")
  s

renderSeriesGraphs = (selector) ->
  $selector = $(selector)
  
  renderGraph = (index, div) ->
    $div = $(div)
    $modal_info = $div.prev()
    values = eval($div.text())
    if values.length > 0
      values[1] = values[0]  if values.length == 1
      id = $div.attr("id")
      canvas = document.createElement("canvas")
      canvas = G_vmlCanvasManager.initElement(canvas)  unless typeof G_vmlCanvasManager == "undefined"
      $canvas = $(canvas)
      $canvas.attr "id", id
      $canvas.attr "width", "287"
      $canvas.attr "height", "46"
      bg = $div.parent().css("background-color")
      $div.replaceWith $canvas
      g = new Bluff.Line(id, "287x46")
      g.tooltips = false
      g.sort = false
      g.hide_title = true
      g.hide_dots = true
      g.hide_legend = true
      g.hide_mini_legend = true
      g.hide_line_numbers = true
      g.hide_line_markers = true
      g.line_width = 1
      g.set_theme 
        colors: [ "#acacac" ]
        marker_color: "#dedede"
        font_color: "#6f6f6f"
        background_colors: [ bg, bg ]
      
      g.data "values", values, "#8888dd"
      g.draw()
      $canvas.click ->
        renderModalGraph $modal_info
  
  renderModalGraph = (elem) ->
    $elem = $(elem)
    title = $elem.find(".modal_graph_title").text()
    xunit = $elem.find(".modal_graph_x_unit").text()
    yunit = $elem.find(".modal_graph_y_unit").text()
    data = eval($elem.find(".modal_graph_data").text())
    $modal = $(".nft_drilldown_dialog")
    $close = $modal.find(".modal_close")
    $modal.find("h1").text title
    $modal.jqm 
      modal: true
      toTop: true
    
    $modal.jqmAddClose $close
    $modal.jqmShow()
    graph = document.getElementById("nft_drilldown_graph")
    
    updateLabels = ->
      $(graph).find("div").each (idx, e) ->
        $e = $(e)
        if $e.css.has("top")
          $e.css "width", parseInt($e.css("width")) + 10
          $e.css "left", -10
          $e.text $e.text() + yunit
        else if $e.css("text-align") == "center"
          $e.css "width", parseInt($e.css("width")) + 15
          $e.text $e.text() + xunit
    
    dyg = new Dygraph(graph, data, 
      labels: [ xunit, yunit ]
      drawCallback: updateLabels
      includeZero: true
    )
  
  $selector.each renderGraph

prepareCategoryUpdate = (div) ->
  $div = $(div)
  $form = $div.find("form")
  $save = $div.find(".dialog-delete")
  $cancel = $div.find(".dialog-cancel")
  $testset = $div.find(".field .testset")
  $date = $div.find(".field .date")
  $product = $div.find(".field .product")
  $catpath = $("dd.category")
  $datespan = $("span.date")
  $donebtn = $("#wizard_buttons a")

  arrow = $("<div/>").html(" &rsaquo; ").text()

  $testset.val $testset.val()
  $product.val $product.val()

  $save.click ->
    targetval = $(".field .target:checked").val()
    versionval = $(".field .version:checked").val()
    typeval = $testset.val()
    hwval = $product.val()
    dateval = $date.val()

    # validate
    $div.find(".error").hide()
    if targetval == ""
      return false
    else if typeval == ""
      $(".error.testset").text("Test set cannot be empty.").show()
      return false
    else if versionval == ""
      return false
    else if dateval == ""
      $(".error.tested_at").text("Test date cannot be empty.").show()
      return false
    else if hwval == ""
      $(".error.product").text("product cannot be empty.").show()
      return false

    # send to server
    data = $form.serialize()
    url = $form.attr("action")

    # update DOM
    #  - update bread crumbs
    #  - update date
    $.post url, data, (data) ->
      console.log $catpath
      $datespan.text data
      $catpath.html htmlEscape(versionval) + arrow + htmlEscape(targetval) + arrow + htmlEscape(typeval) + arrow + htmlEscape(hwval)
      $donebtn.attr "href", "/" + encodeURI(versionval) + "/" + encodeURI(targetval) + "/" + encodeURI(typeval) + "/" + encodeURI(hwval) + "/" + SESSION_ID
    
    $div.jqmHide()
    false

# Add content to the NFT trend graph when it's shown.
#
# Each callback is passed the "hash" object consisting of the
# following properties;
#  w: (jQuery object) The dialog element
#  c: (object) The config object (dialog's parameters)
#  o: (jQuery object) The overlay
#  t: (DOM object) The triggering element

renderNftTrendGraph = (hash) ->
  m_id = hash.t.id.match("[0-9]{1,}$")
  $elem = $("#nft-trend-data-" + m_id)

  data = $elem.children(".nft_trend_graph_data").text()
  # Don't break the whole thing if there's no data - now one can
  # at least close the window
  data = "Date,Value"  unless data

  title = $elem.find(".nft_trend_graph_title").text()
  unit = $elem.find(".nft_trend_graph_unit").text()

  graph = document.getElementById("nft_trend_graph")
  dyg = new Dygraph(graph, data)

  hash.w.find("h1").text title
  hash.w.show()

linkEditButtons = ->
  $("div.editable_area").each (i, node) ->
    $node = $(node)
    contentDiv = $node.children(".editcontent").first()
    rawDiv = contentDiv.next(".editmarkup")
    $node.data "content", contentDiv
    $node.data "raw", rawDiv
    $node.click handleEditButton
  
  $("div.editable_title").click handleTitleEdit

  $(".testcase").each (i, node) ->
    linkTestCaseButtons node
  
  $(".feature_record").each (i, node) ->
    $node = $(node)
    $comment = $node.find(".feature_record_notes")
    $grading = $node.find(".feature_record_grading")
    $comment.click handleFeatureCommentEdit
    $grading.click handleFeatureGradingEdit

unlinkTestCaseButtons = (node) ->
  $node = $(node)
  $comment = $node.find(".testcase_notes")
  $result = $node.find(".testcase_result")

  $result.unbind "click"
  $comment.unbind "click"

linkTestCaseButtons = (node) ->
  $node = $(node)
  $comment = $node.find(".testcase_notes")
  $result = $node.find(".testcase_result")

  $result.click handleResultEdit
  $comment.click handleCommentEdit

handleFeatureGradingEdit = ->
  $node = $(this)
  $span = $node.find("span")
  return false  if $span.is(":hidden")

  $feature = $node.closest(".feature_record")
  id = $feature.attr("id").substring(8)
  $form = $("#feature_grading_edit_form form").clone()
  $form.find(".id_field").val id
  $select = $form.find("select")

  $div = $feature.find(".feature_record_grading_content")

  grading = $div.text()
  code = "0"
  if grading == "Red"
    code = "1"
  else if grading == "Yellow"
    code = "2"
  else code = "3"  if grading == "Green"

  $select.find("option[selected=\"selected\"]").removeAttr "selected"
  $select.find("option[value=\"" + code + "\"]").attr "selected", "selected"

  $node.unbind "click"
  $node.removeClass "edit"

  $form.submit handleFeatureGradingSubmit
  $select.change ->
    $select.unbind "blur"
    if $select.val() == code
      $form.detach()
      $span.show()
      $node.addClass "edit"
      $node.click handleFeatureGradingEdit
    else
      $form.submit()
  
  $select.blur ->
    $form.detach()
    $span.show()
    $node.addClass "edit"
    $node.click handleFeatureGradingEdit
  
  $span.hide()
  $form.insertAfter $div
  $select.focus()
  false

handleFeatureGradingSubmit = ->
  $form = $(this)
  data = $form.serialize()
  url = $form.attr("action")

  $node = $form.closest("td")
  $node.addClass("edit").click handleFeatureGradingEdit

  $span = $node.find("span")
  $feature = $form.closest(".feature_record_grading")
  $div = $feature.find(".feature_record_grading_content")

  $span.removeClass "grading_white grading_red grading_yellow grading_green"
  result = $form.find("select").val()
  if result == "1"
    $span.addClass "grading_red"
    $div.text "Red"
  else if result == "2"
    $span.addClass "grading_yellow"
    $div.text "Yellow"
  else if result == "3"
    $span.addClass "grading_green"
    $div.text "Green"
  else
    $span.addClass "grading_white"
    $div.text "N/A"

  $form.detach()
  $span.show()
  $.post url, data
  false

handleFeatureCommentEdit = ->
  $node = $(this)
  $div = $node.find("div.content")
  return false  if $div.is(":hidden")

  $feature = $node.closest(".feature_record")
  $form = $("#feature_comment_edit_form form").clone()

  $field = $form.find(".comment_field")
  id = $feature.attr("id").substring(8)
  $form.find(".id_field").val id

  markup = $feature.find(".comment_markup").text()
  $field.autogrow()
  $field.val markup

  $form.submit handleFeatureCommentFormSubmit
  $form.find(".cancel").click ->
    $form.detach()
    $div.show()
    $node.click handleFeatureCommentEdit
    $node.addClass "edit"
    false
  
  $node.unbind "click"
  $node.removeClass "edit"
  $div.hide()
  $form.insertAfter $div

  $field.change()
  $field.focus()
  false


handleFeatureCommentFormSubmit = ->
  $form = $(this)
  $feature = $form.closest(".feature_record")
  $div = $feature.find(".feature_record_notes div.content")
  markup = $form.find(".comment_field").val()

  data = $form.serialize()
  url = $form.attr("action")
  $feature.find(".comment_markup").text markup
  html = formatMarkup(markup)
  $div.html html
  $form.detach()
  $div.show()
  $feature.find(".feature_record_notes").click(handleFeatureCommentEdit).addClass "edit"

  $.post url, data
  fetchBugzillaInfo()
  false

handleResultEdit = ->
  $node = $(this)
  $span = $node.find("span")
  return false  if $span.is(":hidden")

  $testcase = $node.closest(".testcase")
  id = $testcase.attr("id").substring(9)
  $form = $("#result_edit_form form").clone()
  $form.find(".id_field").val id
  $select = $form.find("select")

  result = $span.text()

  code = "0"
  if result == "Pass"
    code = "1"
  else code = "-1"  if result == "Fail"

  $select.find("option[selected=\"selected\"]").removeAttr "selected"
  $select.find("option[value=\"" + code + "\"]").attr "selected", "selected"

  $node.unbind "click"
  $node.removeClass "edit"

  $form.submit handleResultSubmit
  $select.change ->
    $select.unbind "blur"
    if $select.val() == code
      $form.detach()
      $span.show()
      $node.addClass "edit"
      $node.click handleResultEdit
    else
      $form.submit()
  
  $select.blur ->
    $form.detach()
    $span.show()
    $node.addClass "edit"
    $node.click handleResultEdit
  
  $span.hide()
  $form.insertAfter $span
  $select.focus()
  false



  handleResultSubmit = ->
  $form = $(this)

  data = $form.serialize()
  url = $form.attr("action")

  $node = $form.closest("td")
  $node.addClass("edit").removeClass("pass fail na").click handleResultEdit

  $span = $node.find("span")
  result = $form.find("select").val()

  if result == "1"
    $node.addClass "pass"
    $span.text "Pass"
  else if result == "-1"
    $node.addClass "fail"
    $span.text "Fail"
  else
    $node.addClass "na"
    $span.text "N/A"

  $form.detach()
  $span.show()
  $.post url, data
  false

handleCommentEdit = ->
  $node = $(this)
  $div = $node.find("div.content")
  return false  if $div.is(":hidden")

  $testcase = $node.closest(".testcase")
  $form = $("#comment_edit_form form").clone()
  $field = $form.find(".comment_field")

  attachment_url = $div.find(".note_attachment").attr("href") or ""
  attachment_filename = attachment_url.split("/").pop()

  $current_attachment = $form.find("div.attachment:not(.add)")
  $add_attachment = $form.find("div.attachment.add")

  if attachment_url == "" or attachment_filename == ""
    $current_attachment.hide()
  else
    $add_attachment.hide()

    $attachment_link = $current_attachment.find("#attachment_link")
    $attachment_link.attr "href", attachment_url
    $attachment_link.html attachment_filename

    $current_attachment.find("input").attr "value", attachment_filename

    $current_attachment.find(".delete").click ->
      $attachment_field = $(this).closest(".field")
      $current_attachment = $attachment_field.find("div.attachment:not(.add)")
      $add_attachment = $attachment_field.find("div.attachment.add")

      $current_attachment.hide()
      $current_attachment.find("input").attr "value", ""
      $add_attachment.show()

  id = $testcase.attr("id").substring(9)
  $form.find(".id_field").val id

  markup = $testcase.find(".comment_markup").text()
  $field.autogrow()
  $field.val markup

  $form.submit handleCommentFormSubmit
  $form.find(".cancel").click ->
    $form.detach()
    $div.show()
    $node.click handleCommentEdit
    $node.addClass "edit"
    false
  
  $node.unbind "click"
  $node.removeClass "edit"
  $div.hide()
  $form.insertAfter $div
  $field.change()
  $field.focus()
  false

handleCommentFormSubmit = ->
  $form = $(this)
  $testcase = $form.closest(".testcase")
  $div = $testcase.find(".testcase_notes div.content")
  markup = $form.find(".comment_field").val()
  data = $form.serialize()
  url = $form.attr("action")
  $testcase.find(".comment_markup").text markup
  html = formatMarkup(markup)
  $div.html html
  $form.hide()
  $div.show()
  $testcase.find(".testcase_notes").click(handleCommentEdit).addClass "edit"
  options = 
    datatype: "xml"
    success: (responseText, statusText, xhr, $form) ->
      $testcase.find(".testcase_notes").html responseText
      fetchBugzillaInfo()
  
  $form.ajaxSubmit options
  false

handleTitleEdit = ->
  $button = $(this)
  $content = $button.children("h1").find("span.content")
  return false  if $content.is(":hidden")

  title = $content.text()
  $form = $("#title_edit_form form").clone()

  $field = $form.find(".title_field")
  $field.val title

  $form.data "original", $content
  $form.data "button", $button

  $button.removeClass "editable_text"
  $form.submit handleTitleEditSubmit
  $form.find(".save").click ->
    $form.submit()
    false
  
  $form.find(".cancel").click ->
    $form.detach()
    $content.show()
    $button.addClass "editable_text"
    false
  
  $content.hide()
  $form.insertAfter $content
  $field.focus()
  false

handleTitleEditSubmit = ->
  $form = $(this)
  $content = $form.data("original")
  title = $form.find(".title_field").val()
  $content.text title

  data = $form.serialize()
  action = $form.attr("action")
  $button = $form.data("button")
  $.post action, data, ->
  
  $button.addClass "editable_text"
  $form.detach()
  $content.show()
  false

handleDateEdit = ->
  $button = $(this)
  $content = $button.find("span.content").first()
  $raw = $content.next("span.editmarkup")
  return false  if $content.is(":hidden")

  data = $raw.text()
  $form = $("#date_edit_form form").clone()
  $field = $form.find(".date_field")
  $field.val data

  $form.data("original", $content).data("raw", $raw).data "button", $button
  $form.submit handleDateEditSubmit
  $form.find(".save").click ->
    $form.submit()
    false
  
  $form.find(".cancel").click ->
    $form.detach()
    $content.show()
    $button.addClass "editable_text"
    false
  
  $content.hide()
  $form.insertAfter $content
  $field.focus()
  addDateSelector $field
  $button.removeClass "editable_text"
  false

handleDateEditSubmit = ->
  $form = $(this)
  $content = $form.data("original")
  $raw = $form.data("raw")
  data = $form.find(".date_field").val()
  $raw.text data

  data = $form.serialize()
  action = $form.attr("action")
  $button = $form.data("button")
  $.post action, data, (data) ->
    $content.text data
  
  $button.addClass "editable_text"
  $form.detach()
  $content.show()
  false

handleEditButton = ->
  $button = $(this)
  $div = $button.data("content")
  return false  if $div.is(":hidden")

  $raw = $button.data("raw")
  fieldName = $div.attr("id")
  text = $.trim($raw.text())
  $form = $($("#txt_edit_form form").clone())
  $area = $($form.find("textarea"))
  $area.attr "name", "meego_test_session[" + fieldName + "]"
  $area.autogrow()
  $area.val text

  $form.data "original", $div
  $form.data "markup", $raw
  $form.data "button", $button
  $form.submit handleTextEditSubmit
  $form.find(".save").click ->
    $form.submit()
    false
  
  $form.find(".cancel").click ->
    $form.detach()
    $div.show()
    $button.addClass "editable_text"
    false
  
  $button.removeClass "editable_text"
  $div.hide()
  $form.insertAfter $div
  $area.change()
  $area.focus()
  false

removeAttachment = (report, fileName, callback) ->
  $.post "/ajax_remove_attachment", 
    id: report
    name: fileName
  , (data, status) ->
    callback.call this  if data.ok == 1 and callback?

toggleRemoveTestCase = (eventObject) ->
  $testCaseRow = $(eventObject.target).closest(".testcase")
  id = $testCaseRow.attr("id").split("-").pop()

  if $testCaseRow.hasClass("removed")
    restoreTestCase id, ->
    
    linkTestCaseButtons $testCaseRow
  else
    removeTestCase id, ->
    
    unlinkTestCaseButtons $testCaseRow

  $nftRows = $(".testcase-nft-" + id.toString())
  if $nftRows.length == 0
    $testCaseRow.toggleClass "removed"
  else
    $nftRows.toggleClass "removed"

  $testCaseRow.find(".testcase_name").toggleClass "removed"
  $testCaseRow.find(".testcase_name a").toggleClass "remove_list_item"
  $testCaseRow.find(".testcase_name a").toggleClass "undo_remove_list_item"
  $testCaseRow.find(".testcase_notes").toggleClass "edit"
  $testCaseRow.find(".testcase_result").toggleClass "edit"

removeTestCase = (id, callback) ->
  $.post "/ajax_remove_testcase", id: id, (data, status) ->
    callback.call this  if data.ok == 1 and callback?

restoreTestCase = (id, callback) ->
  $.post "/ajax_restore_testcase", id: id, (data, status) ->
    callback.call this  if data.ok == 1 and callback?

(($) ->
  # auto-growing text areas
  $.fn.autogrow = (options) ->
    @filter("textarea").each ->
      $this = $(this)
      minHeight = $this.height()
      lineHeight = $this.css("lineHeight")
      shadow = $("<div></div>").css(
        position: "absolute"
        top: -10000
        left: -10000
        width: $(this).width() - parseInt($this.css("paddingLeft")) - parseInt($this.css("paddingRight"))
        fontSize: $this.css("fontSize")
        fontFamily: $this.css("fontFamily")
        lineHeight: $this.css("lineHeight")
        resize: "none"
      ).appendTo(document.body)
      update = ->
        times = (string, number) ->
          _res = ""
          i = 0
          
          while i < number
            _res = _res + string
            i++
          _res
        
        val = @value.replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/&/g, "&amp;").replace(/\n$/, "<br/>&nbsp;").replace(/\n/g, "<br/>").replace(RegExp(" {2,}", "g"), (space) ->
          times("&nbsp;", space.length - 1) + " "
        )
        shadow.html val
        $(this).css "height", Math.max(shadow.height() + 20, minHeight)
      
      $(this).change(update).keyup(update).keydown update
      update.apply this
    
    this
) jQuery

handleTextEditSubmit = ->
  $form = $(this)
  $original = $form.data("original")
  $markup = $form.data("markup")
  $area = $form.find("textarea")
  text = $area.val()

  $button = $form.data("button")
  $button.addClass "editable_text"

  if $markup.text() == text
    $form.detach()
    $original.show()
    return false

  $markup.text text
  data = $form.serialize()
  action = $form.attr("action")
  $.post action, data, ->
  
  $original.html formatMarkup(text)
  $form.detach()
  $original.show()
  fetchBugzillaInfo()
  false

applyBugzillaInfo = (node, info) ->
  $node = $(node)
  if info == undefined
    $node.addClass "invalid"
  else
    status = info.status
    if status == "RESOLVED" or status == "VERIFIED"
      $node.addClass "resolved"
      status = info.resolution
    else
      $node.addClass "unresolved"
    text = info.summary
    unless $node.closest("td.testcase_notes").length == 0
      text = text + " (" + status + ")"
      $node.attr "title", text
    else if $node.hasClass("bugzilla_append")
      text = text + " (" + status + ")"
      $node.after "<span> - " + text + "</span>"
    else
      $node.text text
      $node.attr "title", status
  $node.removeClass "fetch"

fetchBugzillaInfo = ->
  bugIds = []
  searchUrl = "/fetch_bugzilla_data"
  links = $(".bugzilla.fetch")

  links.each (i, node) ->
    id = $.trim($(node).text())
    if id of bugzillaCache
      applyBugzillaInfo node, bugzillaCache[id]
    else
      bugIds.push id  if $.inArray(id, bugIds) == -1
  
  return  if bugIds.length == 0

  $.get searchUrl, "bugids[]=" + bugIds.toString(), (csv) ->
    data = CSVToArray(csv)
    hash = []
    i = 1
    
    while i < data.length
      row = data[i]
      id = row[0]
      summary = row[1]
      status = row[2]
      resolution = row[3]
      hash[id.toString()] = 
        summary: row[1]
        status: row[2]
        resolution: row[3]
      i++

    $(".bugzilla.fetch").each (i, node) ->
      id = $.trim($(node).text())
      if id of bugzillaCache
        info = bugzillaCache[id]
      else
        info = hash[id]
        bugzillaCache[id] = info  unless info == undefined
      applyBugzillaInfo node, info


setTableLoaderSize = (tableID, loaderID) ->
  t = $(tableID)
  h = t.height()
  $(loaderID).height h


CSVToArray = (strData, strDelimiter) ->
  strDelimiter = (strDelimiter or ",")
  objPattern = new RegExp(("(\\" + strDelimiter + "|\\r?\\n|\\r|^)" + "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" + "([^\"\\" + strDelimiter + "\\r\\n]*))"), "gi")
  arrData = [ [] ]
  arrMatches = null
  while arrMatches = objPattern.exec(strData)
    strMatchedDelimiter = arrMatches[1]
    arrData.push []  if strMatchedDelimiter.length and (strMatchedDelimiter != strDelimiter)
    if arrMatches[2]
      strMatchedValue = arrMatches[2].replace(new RegExp("\"\"", "g"), "\"")
    else
      strMatchedValue = arrMatches[3]
    arrData[arrData.length - 1].push strMatchedValue
  arrData



jQuery ($) ->
  dragenter = (e) ->
    e.stopPropagation()
    e.preventDefault()
    $("#dropbox").addClass "draghover"
    false
  dragover = (e) ->
    e.stopPropagation()
    e.preventDefault()
    $("#dropbox").addClass "draghover"
    false
  dragleave = (e) ->
    e.stopPropagation()
    e.preventDefault()
    $("#dropbox").removeClass "draghover"
    false
  drop = (e) ->
    e.stopPropagation()
    e.preventDefault()
    $("#dropbox").removeClass "draghover"
    $("#dropbox").addClass "dropped"

    if typeof e.originalEvent.dataTransfer == "undefined"
      files = e.originalEvent.target.files
    else
      files = e.originalEvent.dataTransfer.files
    handleFiles files
    false

  handleFiles = (files) ->
    i = 0
    
    while i < files.length
      file = files[i]
      file_extension = file.name.split(".").pop().toLowerCase()
      allowed_extensions = [ "xml", "csv" ]
      if file.fileSize < 1048576 and jQuery.inArray(file_extension, allowed_extensions) != -1
        if firstdrop
          $("#dropbox").text ""
          firstdrop = false
        file.id = "file" + fileid
        fileid = fileid + 1
        source = $("script[name=attachment]").html()
        template = Handlebars.compile(source)
        data = 
          filename: file.name
          fileid: file.id
        
        result = template(data)
        $("#dropbox").append result
        queue.push file
      i++
    sendItemInQueue()

  handleAjaxResponse = ->
    if @readyState == 4
      $("form input[type=submit]").removeAttr "disabled"
      response = JSON.parse(@responseText)
      tag = "#" + response.fileid
      $(tag + " input").attr "value", response.url
      $(tag + " img").hide()
      sendItemInQueue()
      
  sendItemInQueue = ->
    if queue.length > 0
      file = queue.pop()
      xhr = new XMLHttpRequest()
      xhr.open "post", "/upload_report/", true
      xhr.onreadystatechange = handleAjaxResponse
      xhr.setRequestHeader "Content-Type", "application/octet-stream"
      xhr.setRequestHeader "If-Modified-Since", "Mon, 26 Jul 1997 05:00:00 GMT"
      xhr.setRequestHeader "Cache-Control", "no-cache"
      xhr.setRequestHeader "X-Requested-With", "XMLHttpRequest"
      xhr.setRequestHeader "X-File-Name", file.fileName
      xhr.setRequestHeader "X-File-Size", file.fileSize
      xhr.setRequestHeader "X-File-Type", file.type
      xhr.setRequestHeader "X-File-Id", file.id
      xhr.send file
      $("form input[type=submit]").attr "disabled", "true"
  firstdrop = true
  fileid = 1
  queue = []
  if typeof window.FileReader == "function"
    $("#only_browse").remove()
    $("#dragndrop_and_browse").show()
    $("#dropbox").bind("dragenter", dragenter).bind("dragover", dragover).bind("dragleave", dragleave).bind "drop", drop
  else
    $("#dragndrop_and_browse").remove()
    

formatMarkup = (s) ->
  s = htmlEscape s

  lines = s.split '\n'
  html = ""
  ul = false
  for line in lines
    line = $.trim line
    if ul and not /^\*/.test line
      html += "</ul>"
      ul = false
    else if line == ""
      html += "<br>"
    
    if line == ""
      continue
    
    line = line.replace(/'''''(.+?)'''''/g, "<b><i>$1</i></b>")
    line = line.replace(/'''(.+?)'''/g, "<b>$1</b>")
    line = line.replace(/''(.+?)''/g, "<i>$1</i>")
    line = line.replace(/http\:\/\/([^\/]+)\/show_bug\.cgi\?id=(\d+)/g, "<a class=\"bugzilla fetch bugzilla_append\" href=\"http://$1/show_bug.cgi?id=$2\">$2</a>")
    line = line.replace(/\[\[(http[s]?:\/\/.+?) (.+?)\]\]/g, "<a href=\"$1\">$2</a>")
    line = line.replace(/\[\[(\d+)\]\]/g, "<a class=\"bugzilla fetch bugzilla_append\" href=\"" + BUGZILLA_URI + "$1\">$1</a>")

    line = line.replace(/^====\s*(.+)\s*====$/, "<h5>$1</h5>")
    line = line.replace(/^===\s*(.+)\s*===$/, "<h4>$1</h4>")
    line = line.replace(/^==\s*(.+)\s*==$/, "<h3>$1</h3>")
    match = /^\*(.+)$/.exec(line)

    if match
      if not ul
        html += "<ul>"
        ul = true
      html += "<li>" + match[1] + "</li>"
    else if not /^<h/.test(line)
      html += line + "<br/>"
    else
      html += line

  return html

filterResults = (rowsToHide, typeText) ->
  updateToggle = ($tbody, $this) ->
    count = $tbody.find("tr:hidden").length
    if count > 0
      $this.text("+ see " + count + " " + typeText)
    else
      $this.text("- hide " + typeText)
    
    if $tbody.find(rowsToHide).length == 0
      $this.hide()

  updateToggles = ->
    $("a.see_all_toggle").each ->
      $tbody = $(this).parents("tbody").next("tbody")
      updateToggle($tbody, $(this))

  $(".see_history_button").click ->
    $("#detailed_functional_test_results").hide()
    $history.show()
    $history.find(".see_history_button").addClass "active"
    false

  $(".see_all_button").click ->
    $("a.sort_btn").removeClass "active"
    $(this).addClass "active"
    $(rowsToHide).show()
    updateToggles()
    false

  $(".see_only_failed_button").click ->
    $("a.sort_btn").removeClass "active"
    $(this).addClass "active"
    $(rowsToHide).hide()
    updateToggles()
    false

  updateToggles()

  $("a.see_all_toggle").each ->
    $(this).click (index, item) ->
      $this = $(this)
      $tbody = $this.parents("tbody").next("tbody")
      $tbody.find(rowsToHide).toggle
      updateToggle($tbody, $this)
      false
  
  $detail  = $("table.detailed_results").first()
  $history = $("table.detailed_results.history")
  $history.find(".see_all_button").click ->
    $history.hide()
    $detail.show()
    $detail.find(".see_all_button").click()
  $history.find(".see_only_failed_button").click ->
    $history.hide()
    $detail.show()
    $detail.find(".see_only_failed_buttton").click()
    