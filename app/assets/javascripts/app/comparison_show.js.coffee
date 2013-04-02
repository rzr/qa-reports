$(document).ready () ->
    filterResults("tr.testcase:not(.has_changes)", "unchanged tests")
    fetchExternalInfo()
