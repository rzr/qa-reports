# Stuff moved away from old huge application.js that is needed
# in more than one place. We are not using modules, and Sprocket
# will create the closure wrapper so we need to put these in global
# scope

@activateSuggestionLinks = (target) ->
  $(target).find(".suggestions a").on 'click', (e) ->
    e.preventDefault()
    $a = $(this)
    $a.parent().prevAll('input').val $a.text()


@filterResults = (rowsToHide, typeText) ->
  updateToggle = ($tbody, $this) ->
    count = $tbody.find("tr:hidden").length
    if count > 0
      $this.text("+ see #{count} #{typeText}")
    else
      $this.text("- hide #{typeText}")

    if $tbody.find(rowsToHide).length == 0
      $this.hide()

  updateToggles = ->
    $("a.see_all_toggle").each ->
      $tbody = $(this).parents("tbody").next("tbody")
      updateToggle($tbody, $(this))


  $(".see_feature_build_button").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $("a#detailed_feature.sort_btn").removeClass("active")
    $("#test_results_by_feature").hide()
    $feature_build.show()
    $(this).addClass("active")

  $(".see_feature_comment_button").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $("a#detailed_feature.sort_btn").removeClass("active")
    $("#test_feature_build_results").hide()
    $feature_details.show()
    $(this).addClass("active")

  $(".see_the_same_build_button").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $("a#detailed_case.sort_btn").removeClass("active")
    $("#detailed_functional_test_results").hide()
    $build.show()
    $build.find(".see_the_same_build_button").addClass("active")

  $(".see_history_button").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $("a#detailed_case.sort_btn").removeClass("active")
    $("#detailed_functional_test_results").hide()
    $history.show()
    $history.find(".see_history_button").addClass("active")

  $(".see_all_button").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $("a#detailed_case.sort_btn.non_nft_button").removeClass("active")
    $(this).addClass("active")
    $(rowsToHide).show()
    updateToggles()

  $(".see_all_comparison_button").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $("a.see_only_failed_comparison_button.sort_btn").removeClass("active")
    $(this).addClass("active")
    $(rowsToHide).show()
    updateToggles()

  $(".see_only_failed_button").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $("a#detailed_case.sort_btn.non_nft_button").removeClass("active")
    $("a#detailed_case.sort_btn").removeClass("active")
    $(this).addClass("active")
    $(rowsToHide).hide()
    updateToggles()

  $(".see_only_failed_comparison_button").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $("a.see_all_comparison_button.sort_btn").removeClass("active")
    $(this).addClass("active")
    $(rowsToHide).hide()
    updateToggles()

  updateToggles()

  $("a.see_all_toggle").each ->
    $(this).click (e) ->
      e.preventDefault()
      e.stopPropagation()
      $this = $(this)
      $tbody = $this.parents("tbody").next("tbody")
      $tbody.find(rowsToHide).toggle()
      updateToggle($tbody, $this)

  $detail  = $("table.detailed_results").first()
  $history = $("table.detailed_results.history")
  $build   = $("table.detailed_results.build")
  $feature_details = $("table.feature_detailed_results").first()
  $feature_build   = $("table.feature_detailed_results_with_build_id")

  $history.find(".see_all_button").click ->
      $history.hide()
      $detail.show()
      $detail.find(".see_all_button").click()

  $history.find(".see_only_failed_button").click ->
      $history.hide()
      $detail.show()
      $detail.find(".see_only_failed_button").click()

  $history.find(".see_the_same_build_button").click ->
      $history.hide()
      $build.show()
      $detail.find(".see_the_same_build_button").click()

  $build.find(".see_all_button").click ->
      $build.hide()
      $detail.show()
      $detail.find(".see_all_button").click()

  $build.find(".see_only_failed_button").click ->
      $build.hide()
      $detail.show()
      $detail.find(".see_only_failed_button").click()

  $build.find(".see_history_button").click ->
      $build.hide()
      $history.show()
      $detail.find(".see_the_history_button").click()

  $feature_build.find(".see_feature_comment_button").click ->
      $feature_build.hide()
      $feature_details.show()
      $feature_details.find(".see_feature_comment_button").click()

  # NFT history

  $nft_detail  = $("table.non-functional_results.detailed_results").first()
  $nft_history = $("table.non-functional_results.detailed_results.history")

  $(".see_nft_history_button").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $nft_detail.hide()
    $nft_history.show()

  $(".see_latest_button").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $nft_history.hide()
    $nft_detail.show()
