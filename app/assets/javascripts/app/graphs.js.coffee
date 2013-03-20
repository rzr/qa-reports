#
# NFT graphs (serial, modals, history)
#

@renderNftTrendGraph = (m_id) ->
  $modal = $("#nft_trend_dialog")
  $elem  = $("#nft-trend-data-#{m_id}")

  # Set zeroes if no data exists so the modal works
  data  = $elem.children(".nft_trend_graph_data").text() || "Date,Value\n0,0"
  title = $elem.find(".nft_trend_graph_title").text()
  graph = document.getElementById("nft_trend_graph")

  $modal.find("h1").text(title)
  $modal.jqmShow()

  dyg = new Dygraph(graph, data)

@renderSeriesGraphs = (selector) ->
  $selector = $(selector)

  renderGraph = (index, div) ->
    $div        = $(div)
    $modal_info = $div.prev()
    values      = eval($div.text())

    if values.length > 0
      values[1] = values[0] if values.length == 1

      id     = $div.attr("id")
      canvas = document.createElement("canvas")
      # if it is IE
      canvas  = G_vmlCanvasManager.initElement(canvas) if G_vmlCanvasManager?
      $canvas = $(canvas)

      $canvas.attr("id", id)
      $canvas.attr("width", "287")
      $canvas.attr("height", "46")

      bg = $div.parent().css("background-color")
      $div.replaceWith($canvas)

      g = new Bluff.Line(id, '287x46')
      g.tooltips = false
      g.sort     = false

      g.hide_title  = true
      g.hide_dots   = true
      g.hide_legend = true
      g.hide_mini_legend  = true
      g.hide_line_numbers = true
      g.hide_line_markers = true

      g.line_width = 1

      g.set_theme
        colors:       ['#acacac'],
        marker_color: '#dedede',
        font_color:   '#6f6f6f',
        background_colors: [bg, bg]

      g.data("values", values, "#8888dd")
      g.draw()

      $canvas.click ->
        # Render NftTrendGraph, the same that is shown in See latest
        # -mode when clickin the measurement value
        if $div.hasClass('nft_history')
          m_id = id.match("[0-9]{1,}$")
          renderNftTrendGraph(m_id)
        # Open NFT serial measurement graph
        else if $div.hasClass('nft_serial_history')
          renderNftSerialTrendGraph($modal_info)
        else
          renderModalGraph($modal_info)

  renderModalGraph = (elem) ->
      $elem = $(elem)
      title = $elem.find(".modal_graph_title").text()
      xunit = $elem.find(".modal_graph_x_unit").text()
      yunit = $elem.find(".modal_graph_y_unit").text()
      data  = eval($elem.find(".modal_graph_data").text())

      $modal = $(".nft_drilldown_dialog")
      $close = $modal.find(".modal_close")

      $modal.find("h1").text(title)
      $modal.jqm(modal: true, toTop: true)
      $modal.jqmAddClose($close)
      $modal.jqmShow()

      graph = document.getElementById("nft_drilldown_graph")

      updateLabels = ->
        $(graph).find("div.dygraph-axis-label-x").each (idx, e) ->
          $e = $(e)
          $e.parent().css("width", parseInt($e.css("width"))+15)
          $e.text($e.text() + xunit)

        $(graph).find("div.dygraph-axis-label-y").each (idx, e) ->
          $e = $(e)
          $e.parent()
            .css("width", parseInt($e.css("width"))+10)
            .css("left", -10)
          $e.text($e.text() + yunit)

      dyg = new Dygraph graph, data,
        labels:       [xunit, yunit],
        drawCallback: updateLabels,
        includeZero:  true

  renderNftSerialTrendGraph = (elem) ->
    updateNftSerialTrendGraphData = (dyg) ->
      $modal     = $("#nft_series_history_dialog")
      visibility = [true, true, true, true]

      # Change Dygraph series visibility based on the checkboxes
      # Note: the checkboxes have value attribute set, and the order
      # needs to match with the CSV columns
      $modal.find(":checkbox").each (i, node) ->
        visibility[parseInt(node.value)] = node.checked

      dyg.updateOptions visibility: visibility


    $modal = $("#nft_series_history_dialog")
    $elem  = $(elem)
    title  = $elem.find(".nft_serial_trend_graph_title").text()
    data   = $elem.children(".nft_serial_trend_graph_data").text()

    $modal.find("h1").text(title)
    $modal.jqmShow()

    # Again some data must exist for modal to work
    data ||= "Date,Max. value,Avg. value,Med. value,Min. value\n0,0,0,0,0"

    graph = document.getElementById("nft_series_history_graph")
    dyg   = new Dygraph graph, data,
      colors: ["#2a7438", "#6c3d0f", "#233a84", "#bb2825"]

    # Serial trend dialog checkboxes
    $modal.find(':checkbox').change ->
      updateNftSerialTrendGraphData(dyg)

    updateNftSerialTrendGraphData(dyg)

  $selector.each(renderGraph)
