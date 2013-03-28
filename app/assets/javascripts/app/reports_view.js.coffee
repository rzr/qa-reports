$(document).ready () ->
    filterResults "tr.result_pass", "passing tests"
    fetchExternalInfo()
    $('#delete-dialog').jqm(modal:true).jqmAddTrigger('#delete-button')
