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




