$(document).ready ->
  testSetSuggestions = []
  productSuggestions = []

  updateProductSuggestions = (data) ->
    productSuggestions = data
    $("#report_test_product").autocomplete(source: productSuggestions)
    activateSuggestionLinks("div.field")

  updateTestSetSuggestions = (data) ->
    testSetSuggestions = data
    $("#report_test_type").autocomplete(source: testSetSuggestions)
    activateSuggestionLinks("div.field")

  product_url = window.location.pathname.replace("upload","product")
  testtype_url = window.location.pathname.replace("upload","testset")
  $.get(product_url, updateProductSuggestions)
  $.get(testtype_url, updateTestSetSuggestions)

  $(".date").datepicker(
    showOn: "both",
    buttonImage: "/images/calendar_icon.png",
    buttonImageOnly: true,
    firstDay: 1,
    selectOtherMonths: true,
    dateFormat: "yy-mm-dd"
  )

  myDate = new Date()
  prettyDate = myDate.getUTCFullYear() + '-' + (myDate.getUTCMonth()+1) + '-' + myDate.getUTCDate()
  $(".date").val(prettyDate)
  