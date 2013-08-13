#
# NFT graphs (serial, modals, history)
#

# Notice: the dygraphs here do not work on IE8. They are now properly initiated
# and the mouse over value showing thingie works but the data lines or grid
# are not shown. This could be fixed by using
# <meta http-equiv="X-UA-Compatible" content="IE=EmulateIE7; IE=EmulateIE9">
# in the report but we could lose some other JS/CSS functionality so it is
# not taken in use.

series_label = (s) -> "#{s.name} (#{s.unit})"

@renderNftTrendGraph = (m_id) ->
  $modal = $("#nft_trend_dialog")
  $elem  = $("#nft-trend-data-#{m_id}")

  data      = $.parseJSON $elem.children(".nft_trend_graph_data").text()
  data.data = _.map data.data, (d) -> d[0] = new Date(d[0]); d
  title     = $elem.find(".nft_trend_graph_title").text()
  labels    = ['Date'].concat(_.map data.series, series_label)

  graph = document.getElementById("nft_trend_graph")
  $modal.find("h1").text(title)
  $modal.jqmShow()

  opts =
    labels: labels
    axes:
      y:
        axisLabelFormatter: (y) -> "#{y} #{data.series[0].unit}"

  dyg = new Dygraph(graph, data.data, opts)

@renderSeriesGraphs = (selector) ->
  bluff_colors = ["#8888dd", "rgb(64,128,0)", "rgb(64,0,128)", "rgb(0,128,128)"]
  $selector    = $(selector)

  renderGraph = (index, div) ->
    $div        = $(div)
    $modal_info = $div.prev()
    values      = $.parseJSON($div.text())

    if values.length > 0
      id      = $div.attr("id")
      canvas  = document.createElement("canvas")
      $canvas = $(canvas)
      bg      = $div.parent().css("background-color")

      # IE, set white background if it would be transparent
      bg = '#fff' if bg == 'transparent'

      $canvas.attr("id", id)
      $canvas.attr("width", "287")
      $canvas.attr("height", "46")

      $div.replaceWith($canvas)

      # if it is IE. We need to put the canvas on the document before
      # initializing it, otherwise won't work
      canvas  = G_vmlCanvasManager.initElement(canvas) if G_vmlCanvasManager?

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

      # Scale if we have exactly two units.
      uniq_units = _.uniq (v.unit for v in values)
      if uniq_units.length == 2
        # Maximum values for the unique units
        max_1st = _(values).filter((v) -> v.unit == uniq_units[0]).map((v) -> _.max v.data).max().valueOf()
        max_2nd = _(values).filter((v) -> v.unit == uniq_units[1]).map((v) -> _.max v.data).max().valueOf()
        # Scale up just in case Bluff happens to have problems drawing very
        # small values
        if max_1st < max_2nd
          ratio = max_2nd / max_1st
          cunit = uniq_units[0]
        else
          ratio = max_1st / max_2nd
          cunit = uniq_units[1]

        for i in [0..values.length - 1]
          values[i].data = (v * ratio for v in values[i].data) if values[i].unit == cunit

      c_index = 0
      for v in values
        # Don't draw just a dot, add a second point with the same value
        # if we have only one data point to show
        v.data[1] = v.data[0] if v.data.length == 1
        g.data v.name, v.data, bluff_colors[c_index]
        c_index = (c_index + 1) % bluff_colors.length
      g.draw()

      $canvas.click (e) ->
        e.preventDefault()
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

      data   = $.parseJSON $elem.find(".modal_graph_data").text()
      labels = [data.interval_unit||""].concat(_.map data.series, series_label)

      $modal = $(".nft_drilldown_dialog")
      $close = $modal.find(".modal_close")

      $modal.find("h1").text(title)
      $modal.jqm(modal: true, toTop: true)
      $modal.jqmAddClose($close)
      $modal.jqmShow()

      graph = document.getElementById("nft_drilldown_graph")

      uniq_units = _(data.series).pluck('unit').uniq().valueOf()

      opts =
        labels:       labels
        includeZero:  true
        connectSeparatedPoints: true
        axes:
          x:
            axisLabelFormatter: (x) -> "#{x}#{labels[0]}"
            valueFormatter:     (x) -> "#{x}#{labels[0]}"
          y:
            axisLabelFormatter: (y) -> "#{y} #{uniq_units[0]}"

      # Two unique units, use two axes
      if uniq_units.length > 1
        opts.series = {}
        for s in data.series
          if s.unit == uniq_units[1]
            opts.series[series_label(s)] = axis: 'y2'
        opts.axes['y2'] =
          drawGrid:           true
          independentTicks:   true
          gridLinePattern:    [2,2]
          axisLabelFormatter: (y2) -> "#{y2} #{uniq_units[1]}"

      dyg = new Dygraph graph, data.data, opts

  renderNftSerialTrendGraph = (elem) ->
    updateNftSerialTrendGraphData = (dyg) ->
      $modal     = $("#nft_series_history_dialog")
      # Each data series has min/max/med/avg, i.e. 4 value. We need thus
      # a visiblity array of num of series * 4. Create this from the labels
      # by slicing off the date
      visibility = (true for d in labels.slice(1))

      $modal.find(":checkbox").each (i, node) ->
        idx = parseInt node.value
        val = node.checked

        while idx < visibility.length
          visibility[idx] = val
          idx += 4
        true

      dyg.updateOptions visibility: visibility


    $modal = $("#nft_series_history_dialog")
    $elem  = $(elem)
    title  = $elem.find(".nft_serial_trend_graph_title").text()

    data = $.parseJSON $elem.children(".nft_serial_trend_graph_data").text()
    # The data is currently an array of objects, each representing a single
    # series on the chart (min/med/avg/max). We now need to merge them all
    # to a single (large) data object for Dygraph.
    # First, collect dates in an array of arrays. The data values will be
    # concatenated to each nested array as are the units.
    show_data  = ([new Date(d[0])] for d in data[0].data)
    labels     = ['Date']
    # As said, each hash in the array represents single series so the unit
    # is the same for all series (min/max...) of a hash
    uniq_units = _(data).map((d) -> d.series[0].unit).uniq().valueOf()

    for d in data
      labels = labels.concat(_.map d.series, series_label)
      for i in [0..d.data.length-1]
        show_data[i] = show_data[i].concat(d.data[i].slice(1))

    $modal.find("h1").text(title)
    $modal.jqmShow()

    opts =
      labels: labels
      colors: ["#2a7438", "#6c3d0f", "#233a84", "#bb2825"]
      axes:
        y:
          axisLabelFormatter: (y) -> "#{y} #{uniq_units[0]}"

    # Two axes
    if uniq_units.length > 1
      opts.series = {}
      for d in data
        if d.series[0].unit == uniq_units[1]
          for s in d.series
            opts.series[series_label(s)] = axis: 'y2'

      opts.axes['y2'] =
        drawGrid:           true
        independentTicks:   true
        gridLinePattern:    [2,2]
        axisLabelFormatter: (y2) -> "#{y2} #{uniq_units[1]}"

    graph = document.getElementById("nft_series_history_graph")
    dyg   = new Dygraph graph, show_data, opts

    # Serial trend dialog checkboxes
    $modal.find(':checkbox').off('change').on 'change', ->
      updateNftSerialTrendGraphData(dyg)

    updateNftSerialTrendGraphData(dyg)

  $selector.each(renderGraph)
