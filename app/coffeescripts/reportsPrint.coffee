$(document).ready ->
  filterResults "tr.result_pass", "passing tests"
  $("#see_all_button").click()
  fetchBugzillaInfo()
