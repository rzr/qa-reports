/*
 * This file is part of meego-test-reports
 *
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 *
 * Authors: Sami Hangaslammi <sami.hangaslammi@leonidasoy.fi>
 * 			Jarno Keskikangas <jarno.keskikangas@leonidasoy.fi>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2.1 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
 */


function formatMarkup(s) {
    s = htmlEscape(s);

    lines = s.split('\n');
    var html = "";
    var ul = false;
    for (var i = 0; i < lines.length; ++i) {
        var line = $.trim(lines[i]);
        if (ul && !/^\*/.test(line)) {
            html += '</ul>';
            ul = false;
        } else if (line == '') {
            html += "<br/>";
        }
        if (line == '') {
            continue;
        }
        line = line.replace(/'''''(.+?)'''''/g, "<b><i>$1</i></b>");
        line = line.replace(/'''(.+?)'''/g, "<b>$1</b>");
        line = line.replace(/''(.+?)''/g, "<i>$1</i>");
        line = line.replace(/http\:\/\/([^\/]+)\/show_bug\.cgi\?id=(\d+)/g, "<a class=\"bugzilla fetch bugzilla_append\" href=\"http://$1/show_bug.cgi?id=$2\">$2</a>");
        line = line.replace(/\[\[(http[s]?:\/\/.+?) (.+?)\]\]/g, "<a href=\"$1\">$2</a>");
        line = line.replace(/\[\[(\d+)\]\]/g, "<a class=\"bugzilla fetch bugzilla_append\" href=\"" + BUGZILLA_URI + "$1\">$1</a>");

        var match;
        line = line.replace(/^====\s*(.+)\s*====$/, "<h5>$1</h5>");
        line = line.replace(/^===\s*(.+)\s*===$/, "<h4>$1</h4>");
        line = line.replace(/^==\s*(.+)\s*==$/, "<h3>$1</h3>");
        match = /^\*(.+)$/.exec(line);
        if (match) {
            if (!ul) {
                html += "<ul>";
                ul = true;
            }
            html += "<li>" + match[1] + "</li>";
        } else if (!/^<h/.test(line)) {
            html += line + "<br/>";
        } else {
            html += line;
        }
    }
    return html;
}

function setTableLoaderSize(tableID, loaderID) {
		t = $(tableID);
//		w = t.width();
		h = t.height();
		$(loaderID).height(h);
	}

// This will parse a delimited string into an array of
// arrays. The default delimiter is the comma, but this
// can be overriden in the second argument.
//
// Originally written by Ben Nadel
// http://www.bennadel.com/blog/1504-Ask-Ben-Parsing-CSV-Strings-With-Javascript-Exec-Regular-Expression-Command.htm
function CSVToArray(strData, strDelimiter) {
    // Check to see if the delimiter is defined. If not,
    // then default to comma.
    strDelimiter = (strDelimiter || ",");

    // Create a regular expression to parse the CSV values.
    var objPattern = new RegExp(("(\\" + strDelimiter + "|\\r?\\n|\\r|^)" +
                        // Quoted fields.
                            "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +
                        // Standard fields.
                            "([^\"\\" + strDelimiter + "\\r\\n]*))"),"gi");


    // Create an array to hold our data. Give the array
    // a default empty first row.
    var arrData = [[]];

    // Create an array to hold our individual pattern
    // matching groups.
    var arrMatches = null;


    // Keep looping over the regular expression matches
    // until we can no longer find a match.
    while (arrMatches = objPattern.exec(strData)) {

        // Get the delimiter that was found.
        var strMatchedDelimiter = arrMatches[ 1 ];

        // Check to see if the given delimiter has a length
        // (is not the start of string) and if it matches
        // field delimiter. If id does not, then we know
        // that this delimiter is a row delimiter.
        if (strMatchedDelimiter.length && (strMatchedDelimiter != strDelimiter)) {
            // Since we have reached a new row of data,
            // add an empty row to our data array.
            arrData.push([]);
        }

        // Now that we have our delimiter out of the way,
        // let's check to see which kind of value we
        // captured (quoted or unquoted).
        if (arrMatches[ 2 ]) {
            // We found a quoted value. When we capture
            // this value, unescape any double quotes.
            var strMatchedValue = arrMatches[ 2 ].replace(new RegExp("\"\"", "g"),"\"");
        } else {
            // We found a non-quoted value.
            strMatchedValue = arrMatches[ 3 ];
        }

        // Now that we have our value string, let's add
        // it to the data array.
        arrData[ arrData.length - 1 ].push(strMatchedValue);
    }
    // Return the parsed data.
    return( arrData );
}

function filterResults(rowsToHide, typeText) {
    var updateToggle = function($tbody, $this) {
        var count = $tbody.find("tr:hidden").length;
        if(count > 0) {
            $this.text("+ see " + count + " " + typeText);
        } else {
            $this.text("- hide " + typeText);
        }
        if($tbody.find(rowsToHide).length == 0) {
            $this.hide();
        }
    }

    var updateToggles = function() {
        $("a.see_all_toggle").each(function() {
          $tbody = $(this).parents("tbody").next("tbody");
          updateToggle($tbody, $(this));
        });
    }



    $(".see_history_button").click(function(){
    	//setTableLoaderSize('#detailed_functional_test_results', '#history_loader');
    	//$('#history_loader').show();
    	//history loader should be visible during AJAX loading
      $("#detailed_functional_test_results").hide();
      $history.show();
      $history.find(".see_history_button").addClass("active");
      return false;
    });

    $(".see_all_button").click(function(){
        $("a.sort_btn").removeClass("active");
        $(this).addClass("active");
        $(rowsToHide).show();
        updateToggles();
        return false;
    });

    $(".see_only_failed_button").click(function(){
        $("a.sort_btn").removeClass("active");
        $(this).addClass("active");
        $(rowsToHide).hide();
        updateToggles();
        return false;
    });

    updateToggles();
    $("a.see_all_toggle").each(function() {
        $(this).click(function(index, item) {
            var $this = $(this);
            $tbody = $this.parents("tbody").next("tbody");
            $tbody.find(rowsToHide).toggle();
            updateToggle($tbody, $this);
            return false;
        });
    });

    var $detail  = $("table.detailed_results").first();
    var $history = $("table.detailed_results.history");
    $history.find(".see_all_button").click(function(){
        $history.hide();
        $detail.show();
        $detail.find(".see_all_button").click();
    });
    $history.find(".see_only_failed_button").click(function(){
        $history.hide();
        $detail.show();
        $detail.find(".see_only_failed_button").click();
    });
}

jQuery(function($) {

    function dragenter(e) {
        e.stopPropagation();
        e.preventDefault();

        $('#dropbox').addClass('draghover');
        return false;
    }

    function dragover(e) {
        e.stopPropagation();
        e.preventDefault();

        $('#dropbox').addClass('draghover');
        return false;
    }

    function dragleave(e) {
        e.stopPropagation();
        e.preventDefault();

        $('#dropbox').removeClass('draghover');
        return false;
    }


    function drop(e) {
        var files;

        e.stopPropagation();
        e.preventDefault();


        $('#dropbox').removeClass('draghover');
        $('#dropbox').addClass('dropped');

        // get files from drag and drop datatransfer or files in case of field change
        if (typeof e.originalEvent.dataTransfer == "undefined") {
            files = e.originalEvent.target.files;
        } else {
            files = e.originalEvent.dataTransfer.files;
        }

        handleFiles(files);
        return false;
    }

    // Kind of a hack, clean up
    var firstdrop = true;
    var fileid = 1;
    var queue = [];

    function handleFiles(files) {
        // process file list
        for (var i = 0; i < files.length; i++) {
            var file = files[i];

            var file_extension = file.name.split('.').pop().toLowerCase();
            var allowed_extensions = ['xml','csv'];

            if (file.fileSize < 1048576 &&
                    jQuery.inArray(file_extension, allowed_extensions) != -1) {

                // First succesful drag'n drop, remove template text
                if (firstdrop) {
                    $('#dropbox').text("");
                    firstdrop = false;
                }

                file.id = 'file' + fileid;
                fileid = fileid + 1;

                var source = $("script[name=attachment]").html();
                var template = Handlebars.compile(source);
                var data = { "filename": file.name, "fileid": file.id };
                result = template(data);
                $("#dropbox").append(result);

                queue.push(file);
            }
        }

        // trigger first item
        sendItemInQueue();
    }

    function handleAjaxResponse() {
        // Is data transfer completed?
        if (this.readyState === 4) {
            // Enable send button until the data transfer has been finished
            $('form input[type=submit]').removeAttr('disabled');

            // Update dropbox
            var response = JSON.parse(this.responseText);
            var tag = '#' + response.fileid;
            $(tag + " input").attr('value', response.url);
            $(tag + " img").hide();

            // process next item
            sendItemInQueue();
        }
    }

    // Send a file from queue
    function sendItemInQueue() {
        if (queue.length > 0) {
            var file = queue.pop();
            var xhr = new XMLHttpRequest();
            xhr.open('post', '/upload_report/', true);

            xhr.onreadystatechange = handleAjaxResponse;

            xhr.setRequestHeader('Content-Type', 'application/octet-stream'); // multipart/form-data
            xhr.setRequestHeader('If-Modified-Since', 'Mon, 26 Jul 1997 05:00:00 GMT');
            xhr.setRequestHeader('Cache-Control', 'no-cache');
            xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
            xhr.setRequestHeader('X-File-Name', file.fileName);
            xhr.setRequestHeader('X-File-Size', file.fileSize);
            xhr.setRequestHeader('X-File-Type', file.type);
            xhr.setRequestHeader('X-File-Id', file.id);
            xhr.send(file);

            // Disable send button until the data transfer has been finished
            $('form input[type=submit]').attr('disabled', 'true');
        }
    }

    // Bind event listeners
    if (typeof window.FileReader === "function") {
        $('#only_browse').remove();
        $('#dragndrop_and_browse').show();
        // We have file API
        $('#dropbox').bind('dragenter', dragenter)
                     .bind('dragover', dragover)
                     .bind('dragleave', dragleave)
                     .bind('drop', drop);
    } else {
        // Fallback to normal file input
        $('#dragndrop_and_browse').remove();
    }
});
