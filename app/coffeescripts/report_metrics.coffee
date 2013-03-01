$(document).ready ->
  labels = $('#metrics_summary_labels').text().split(',')

  $('.metrics_group').each () ->
    id   = $(this).attr('id').split('_').pop()
    data = $(this).next().find('.history')

    if data.length > 0
      # The height of canvas is 0 by default
      $("metrics_canvas_#{id}").css 'height', '210px'
      g = new Bluff.Line "metrics_canvas_#{id}", "395x210"

      g.hide_title = true
      g.tooltips   = true
      g.sort       = false
      g.labels     = labels
      g.marker_font_size = 18
      g.legend_font_size = 18

      g.set_theme
        colors:       ['#bcd483', '#f36c6c', '#ddd']
        marker_color: '#dedede'
        font_color:   '#6f6f6f'
        background_colors: ['white', 'white']

      data.each (i, elem) ->
        $node  = $(elem)
        name   = $node.parent().prev('.name').text()
        unit   = $node.parent().next('.unit').text()
        # It seems there's no concept of unit in Bluff and all data
        # is charted using the same Y axis. Show the unit in the legend
        name   = "#{name} (#{unit})" if unit? and unit != ""

        values = (parseInt num for num in $node.text().split(','))
        # Fix NaN values - not using 0 because in this context 0
        # is not the same than a missing value
        for i in [0..values.length - 1]
          values[i] = null if isNaN values[i]

        g.data name, values

      g.draw()
