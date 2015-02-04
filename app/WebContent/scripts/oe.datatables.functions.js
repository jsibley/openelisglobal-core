/* Functions to use jquery.datatables in OE.
 * First implementation is in auditTrail in 201209
 */ 

// Needed to make jQuery work with prototype 
// http://docs.jquery.com/Using_jQuery_with_Other_Libraries
jQuery.noConflict();

function localizeByKey (key, locale) {
    if (key == 'label.audittrail.filter') {
    	if (locale.toLowerCase().indexOf('fr') != -1) {
    		return "Filtrer les entrées: ";
    	} else if (locale.toLowerCase().indexOf('vn') != -1) {
    		return "Filter by: ";
    	} else {
    		return "Filter by: ";
    	}
    }
    if (key == 'label.audittrail.filter.limit') {
    	if (locale.toLowerCase().indexOf('fr') != -1) {
    		return "(filtrée à partir de _MAX_)";
    	} else if (locale.toLowerCase().indexOf('vn') != -1) {
    		return "(filtered up to _MAX_)";
    	} else {
    		return "(filtered up to _MAX_)";
    	}
    }
    if (key == 'label.audittrail.none') {
    	if (locale.toLowerCase().indexOf('fr') != -1) {
    		return "Aucun";
    	} else if (locale.toLowerCase().indexOf('vn') != -1) {
    		return "None";
    	} else {
    		return "None";
    	}
    }
    if (key == 'label.audittrail.none.found') {
    	if (locale.toLowerCase().indexOf('fr') != -1) {
    		return "Aucun enregistrement correspondant n'a été trouvé";
    	} else if (locale.toLowerCase().indexOf('vn') != -1) {
    		return "No corresponding matches found";
    	} else {
    		return "No corresponding matches found";
    	}
    }
    if (key == 'label.audittrail.total') {
    	if (locale.toLowerCase().indexOf('fr') != -1) {
    		return "_TOTAL_ entrées appariement";
    	} else if (locale.toLowerCase().indexOf('vn') != -1) {
    		return "_TOTAL_ matches shown";
    	} else {
    		return "_TOTAL_ matches shown";
    	}
    }
}

// jQuery dataTable functions begin
jQuery(document).ready(function ($) {
	// Read parameters from any <script> tags that have them
	var scriptParams = [];
	$("script[params]").each(function() {
		var params = $(this).attr("params").split(',');
		for (var i = 0; i < params.length; i++) {
			scriptParams[params[i].split('=')[0]] = params[i].split('=')[1];
		}
	});
	// Extends Datatables to allow filtering via filterByType dropdown.
    var classFilter = "";
    $.fn.dataTableExt.afnFiltering.push(
        function( oSettings, aData, iDataIndex ) {
          if ( classFilter === "" ) {
            // No class filter applied, so all rows pass
            return true;
          }
          else if ( oSettings.aoData[iDataIndex].nTr.className.indexOf(classFilter) !== -1 ) {
            // TR element has matching class - pass
            return true;
          }
          // No matching class on the row - failed filtering criterion
          return false;
        }
    );
    // Calls the afnFiltering function when filterByType changes
    $('#filterByType').change( function (event) {
        // Store the filter value
        classFilter = $(this).val();
        console.log(classFilter);
        // A full draw will refilter the table
        oTable.fnDraw();
        event.preventDefault();
    });
    // Adds classes to headers when sorting
    $.extend( $.fn.dataTableExt.oStdClasses, {
        "sSortAsc": "header headerSortDown",
        "sSortDesc": "header headerSortUp",
        "sSortable": "header"
    });
    // Converts dates from our display format ( dd/mm/yyyy hh:mm ) to
    // a sortable order
    $.extend( $.fn.dataTableExt.oSort, {
        "date-euro-pre": function ( a ) {
            if ($.trim(a) != '') {
                var frDatea = $.trim(a).split(' ');
                var frTimea = frDatea[1].split(':');
                var frDatea2 = frDatea[0].split('/');
                var x = (frDatea2[2] + frDatea2[1] + frDatea2[0] + frTimea[0] + frTimea[1]) * 1;
            } else {
                var x = 10000000000000; // = l'an 1000 ...
            }
            return x;
            console.log(x);
        },
        "date-euro-asc": function ( a, b ) {
            return a - b;
        },
        "date-euro-desc": function ( a, b ) {
            return b - a;
        }
    });	
    // Applies datatables.js to the #advancedTable
    var oTable = $('#advancedTable').dataTable( {
        "aaSorting": [[1, "asc"]], // Leave sorting blank to use sort produced by database
        "bAutoWidth": false,
        "bPaginate": false, // Turns off pagination
        // Localization settings. Currently hard-coded to French
        "oLanguage": {
            "sSearch": localizeByKey('label.audittrail.filter', scriptParams['locale']),
            "sInfoFiltered": localizeByKey('label.audittrail.filter.limit', scriptParams['locale']),
            "sInfoEmpty": localizeByKey('label.audittrail.none', scriptParams['locale']),
            "sInfo": localizeByKey('label.audittrail.total', scriptParams['locale']),
            "sZeroRecords": localizeByKey('label.audittrail.none.found', scriptParams['locale'])
        },
        // Hides 1st column used for sorting
        "aoColumnDefs": [
    		{ "bVisible": false, "aTargets": [0] },
    		{ "aTargets": [1], "sType": "date-euro" }
        ],
        // Customizes the DOM for the table
        "sDom": "<'row-fluid'<'span12 filter-options'if>r>t<'row-fluid'<'span8'i>>",
        // Table is hidden initially after draw is complete, displays table and
        // controls, hides load message then setCellWidth for scrolling 
        "fnDrawCallback": function( oSettings ) {
        	$("#advancedTable").show();
        	$(".order-details").show();
        	$("#showOptions").css('display', 'inline-block');
            $("#loading").hide();
        }
    }).bind('sort filter', function () {
        // Enables reset button
        $(".reset-sort").removeAttr('disabled');
    });
    // Content to add to table DOM
    $("#showOptions").insertBefore("div.dataTables_filter");
    // Get time the order was created and display
    var getCreateTime = $('.time-stamp:first').html();
    if (getCreateTime != '') {
    	$("#dateCreated").html(getCreateTime);
    	// Get time in system (currentDate - createTime)
        var frDate= $.trim(getCreateTime).split(' ');
        var frDateSplit = frDate[0].split('/');
        var oneDay = 24*60*60*1000; // hours*minutes*seconds*milliseconds
        var frDateMonth = frDateSplit[1] - 1; // Change 1-12 to 0-11
        var entryDate = new Date(frDateSplit[2],frDateMonth,frDateSplit[0]);
        var currentDate = new Date();
        var diffDays = Math.round(Math.abs((currentDate.getTime() - entryDate.getTime())/(oneDay)));
        $("#daysInSystem").html(diffDays);
    }
    // Gets order status from last row of "Ordonnance" that is not
    // an accessionId - FIXME: better to get a value from the database
    var getCurrentStatus = $('tr.Ordonnance').not(":contains('accessionNumber')").last();
    getCurrentStatus = getCurrentStatus.children('td').last().text();
    if (getCurrentStatus != "") {
    	$("#currentStatus").html(getCurrentStatus);
    }   
    // Reset sorting to original order and remove any filtering
    $(".reset-sort").click( function(event) {
        oTable.fnSort( [ [0,'asc'] ] );
        oTable.fnFilter( '' );
        $("#filterByType").val("").change();
    	event.preventDefault();
    });
    
    // Function to get unique values for filter by type
    // Default jquery unique function wasn't working properly for some reason
    var unique = function(origArr) {  
        var newArr = [],  
            origLen = origArr.length,  
            found,  
            x, y;  
        for ( x = 0; x < origLen; x++ ) {  
            found = undefined;  
            for ( y = 0; y < newArr.length; y++ ) {  
                if ( origArr[x] === newArr[y] ) {  
                  found = true;  
                  break;  
                }  
            }  
            if ( !found) newArr.push( origArr[x] );  
        }  
       return newArr;  
    };
	var items=[], options=[];
	//Iterate over td's in type column
	$('#advancedTable tbody tr td.item-cell').each( function(){
	  //add item to array
	  items.push( $(this).text() );
	});
	//Restrict array to unique items
	items = unique( items );
	//Iterate unique array and add options to select
	$.each( items, function(i, item){
	  options.push('<option value="' + item + '">' + item + '</option>');   
	});
	//Append to the select
	$('#filterByType').append( options.join() );
	 
    /*** Featues not yet implemented. ***/

    /* Function used for Bootstrap affix. Leaving out for now due to
     * flakiness in IE.
    // Used to set widths of th and first td row - so bootstrap
    // affix will work properly
    function setCellWidths() {      
        $('#rowHeader th').each(function() {
            var getwidth = $(this).width();
            $(this).css('width', getwidth);
        });
        $('#advancedTable tbody tr:first td').each(function() {
            var getwidth = $(this).width();
            $(this).css('width', getwidth);
        });
    };
    // Gets position to table header to use with Bootstrap affix
    function setHeaderPosition() { 
    	var position = $("#rowHeader").offset();
    	$("#rowHeader").attr('data-offset-top', position.top);
    	console.log(position.top);
    }; */
    /* FIXME - still a work in progress. Need to improve handling
     * when window is resized.
     * Resize columns if window size has changed
    $(window).resize(function() {
        // Pause 250 ms before executing to avoid multiple fires
        // as window resizes
        clearTimeout(this.id);
        this.id = setTimeout(updateCellWidths, 250);
    });
    function updateCellWidths() {      
        $('#advancedTable tbody tr:first').each(function() {
            var getwidth = $(this).width();
            $(this).css('width', getwidth);
            var findTh = $(this).closest('table').find('tr:first').css('width', getwidth);
        })
        $('#rowHeader td').each(function() {
            var getwidth = $(this).width();
            $(this).css('width', getwidth);
            var colIndex = $(this).parent().children().index($(this)) + 1;
            var findTh = $(this).closest('table').find('tbody tr:first td:nth-child(' + colIndex + ')').css('width', getwidth);
            //var rowIndex = $(this).parent().parent().children().index($(this).parent());
            console.log('Column: ' + colIndex + ' th: ' + findTh);
            //var getwidth = $(this).width();
            //$(this).css('width', getwidth);
        })
    };*/
});
