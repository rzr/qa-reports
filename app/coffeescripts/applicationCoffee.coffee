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




