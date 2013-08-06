on_ready_steps = ->
    # IE... the NFT history charts (the small ones) are not drawn if the
    # containing element is hidden when calling renderSeriesGraph. So,
    # show them while drawing. Not pretty but seems to work OK for now.
    if typeof G_vmlCanvasManager != 'undefined'
      $('table.non-functional_results.detailed_results.history').show()
      renderSeriesGraphs ".serial_canvas"
      $('table.non-functional_results.detailed_results.history').hide()
    else
      renderSeriesGraphs ".serial_canvas"

    updateTemplateImage = (params) ->
        attachment_url = params.t.text
        attachment_filename = attachment_url.split('/').pop()

        $('h1#attachment_dialog_header').text attachment_filename
        $('img#attachment_dialog_image').attr 'src', attachment_url
        params.w.show()

    $('#attachment_template').jqm({
      modal:true
      onShow:updateTemplateImage
    }).jqmAddTrigger('.image_attachment').jqmAddClose('.modal_close')

    # Dialog that show history trend for an NFT measurement
    $('#nft_trend_dialog').jqm({
      modal:true,
      topTop:true
    }).jqmAddClose('.modal_close')

    # The link that opens the trend dialog in See latest -mode
    $('.nft_trend_button').click ->
      m_id = $(this).attr("id").match("[0-9]{1,}$")
      renderNftTrendGraph(m_id)
      false

    # Dialog that show NFT serial measurements history in See history -mode
    $('#nft_series_history_dialog').jqm({
      modal:true
    }).jqmAddTrigger('.nft_series_history_modal_toggle').jqmAddClose('.modal_close')

    $('#test_result_overview tr:odd').addClass('odd')
    $('#test_result_overview tr:even').addClass('even')

    $(document).bind 'keydown', (e) ->
      if e.which == 27 and $('.modal_close:visible').length > 0
        e.preventDefault()
        $('.modal_close:visible').click()

# IE hack
if typeof G_vmlCanvasManager != 'undefined'
    $(window).load on_ready_steps
else
    $(document).ready on_ready_steps
