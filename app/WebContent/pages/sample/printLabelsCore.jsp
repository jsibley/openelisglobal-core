<%@ page language="java"
	contentType="text/html; charset=utf-8"
	import="us.mn.state.health.lims.common.action.IActionConstants" %>

<%@ taglib uri="/tags/struts-bean" prefix="bean" %>
<%@ taglib uri="/tags/struts-tiles" prefix="tiles" %>
<bean:define id="formName" value='<%= (String)request.getAttribute(IActionConstants.FORM_NAME) %>' />

<script type="text/javascript">
var requiredFields = new Array("printerName", "masterLabels");

function prePageOnLoad()
{
    var accessionNumber = $("accessionRangeStart");
    accessionNumber.focus();
    setSave();
}

function /*bool*/ requiredFieldsValid(){
    for(var i = 0; i < requiredFields.length; ++i){
        // check if required field exists
        if (!$jq('#' + requiredFields[i]).length)
        	return false;
        if ($jq('#' + requiredFields[i]).is(':input')) {
    		// check for empty input values
        	if ($jq.trim($jq('#' + requiredFields[i]).val()).length === 0)
            	return false;
        } else {
			// check for empty spans/divs
			if ($jq.trim($jq('#' + requiredFields[i]).text()).length === 0)
				return false;
		}
    }
    return true;
}

//disable or enable various buttons/fields based on validity
function setSave() 
{
	//disable or enable print button based on validity/visibility of fields
	var obj = $('printButton'); 
	obj.disabled = true;
	if (isPrintEnabled() && requiredFieldsValid()) 
		obj.disabled = false;
}

function processFailure(xhr) {
  	//ajax call failed
}

function /*void*/ makeDirty(){
    dirty=true;

	if( typeof(showSuccessMessage) != 'undefinded' ){
		showSuccessMessage(false); //refers to last save
	}
    // Adds warning when leaving page if content has been entered into makeDirty form fields
    function formWarning(){ 
    	return "<bean:message key="banner.menu.dataLossWarning"/>";
    }
    window.onbeforeunload = formWarning;
}

<%if( request.getAttribute(IActionConstants.FWD_SUCCESS) != null &&
	      ((Boolean)request.getAttribute(IActionConstants.FWD_SUCCESS)) ) { %>
	if( typeof(showSuccessMessage) != 'undefined' ){
		$jq("#successMsg").text('<bean:message key="print.success"/>');
		showSuccessMessage( true );
	}
<% } %>

function pullDataFromZpl(input) {
	var zplObj = new Object();
	zplObj.accNo = "";
	zplObj.theRest = "";
	var parts = input.split("^FD");
	for (var i = 2; i < parts.length; i++) {
		var pieces = parts[i].split("^FS");
		if ($jq.isNumeric(pieces[0].substring(0,10))) {
			zplObj.accNo = pieces[0].substring(0,10);
		}
		zplObj.theRest += pieces[0] + "<br/>";
	}
	return zplObj;
}

function showZplModal() {
	var zplData = "<%= (String)request.getAttribute("zplData") %>";
	if (zplData.length && zplData != "null") {
		var segs = zplData.split(";;");
		var masterHtml = '';
		var masterZpl = '';
		var itemHtml = '';
		var itemZpl = '';
		for (var i = 1; i < segs.length; i += 2) {
			var masterSeg = segs[i];
		
			if (masterSeg.length) {
				var masterBits = pullDataFromZpl(masterSeg);
				if (!$jq.isEmptyObject(masterBits)) {
					masterHtml += '<div id="masterBarcode' + i + '"></div><div id="masterText' + i + '"></div>';
				}
				masterZpl += masterSeg + "<br/>";
			}
			if (segs[i + 1].length) {
				var itemSegs = segs[i + 1].split("::");
				for (var j = 0; j < itemSegs.length; j++) {
					var itemBits = pullDataFromZpl(itemSegs[j]);
					if (!$jq.isEmptyObject(itemBits)) {
						itemHtml += '<div id="itemBarcode' + i + '-' + j + '"></div><div id="itemText' + i + '-' + j + '"></div>';
					}
					itemZpl += itemSegs[j] + "<br/>";
				}
			}
		}
		$jq("#masterStuff").empty().html(masterHtml);
		$jq("#itemStuff").empty().html(itemHtml);
		for (var i = 1; i < segs.length; i += 2) {
			var masterSeg = segs[i];
		
			if (masterSeg.length) {
				var masterBits = pullDataFromZpl(masterSeg);
				if (!$jq.isEmptyObject(masterBits)) {
					$jq("#masterBarcode" + i).barcode(masterBits.accNo, "code128", {showHRI:false});
					$jq("#masterText" + i).empty().html(masterBits.theRest);
				}
			}
			if (segs[i + 1].length) {
				var itemSegs = segs[i + 1].split("::");
				for (var j = 0; j < itemSegs.length; j++) {
					var itemBits = pullDataFromZpl(itemSegs[j]);
					if (!$jq.isEmptyObject(itemBits)) {
						$jq("#itemBarcode" + i + '-' + j).barcode(itemBits.accNo, "code128", {showHRI:false});
						$jq("#itemText" + i + '-' + j).empty().html(itemBits.theRest);
					}
				}
			}
		}
		$jq("div[id^='itemText'], div[id^='masterText']").css("margin-left", "20px");
		$jq("div[id^='itemBarcode'], div[id^='masterBarcode']").css("padding-top", "15px");
		$jq("#masterZpl").empty().html(masterZpl);
		$jq("#itemZpl").empty().html(itemZpl);
		$jq("#zpl-modal").modal('show');
	}
}
</script>

<!-- Modal code here -->		
<script type="text/javascript">
$jq(document).ready(function () {
			
	// Print Labels Modal definition
	$jq('#zpl-modal').modal({
		backdrop: 'static',
		show: false
	}).css({
		'top': "35%",
		'width': function () { 
			return ($jq(document).width() * .9) + 'px';  
		},
		'max-height': function () { 
			return ($jq(document).height() * .9) + 'px';  
		},
		'margin-left': function () {
			return -($jq(this).width() / 2);
		}
	}).on('show', function() {
		$jq(this).data("modalUpdated", false);
	});
	
	showZplModal();
});
</script>

<tiles:insert attribute="printLabelsContent"/>

<table>
	<tr> 
		<td>
		</td>
		<td>
			<button name="printButton"
				id="printButton"
				type="button"
				onclick="window.onbeforeunload=null;setAction(window.document.forms[0], 'Process', 'no', '?ID=')"
				disabled="disabled"><bean:message key="sample.label.print.button"/></button>
		</td>
		<td>
			<button name="cancelButton"
				id="cancelButtonId"
				type="button"
				onclick="setAction(window.document.forms[0], 'Cancel', 'no', '');"
				><bean:message key="label.button.cancel" /></button>
		</td>
<%if( request.getAttribute(IActionConstants.FWD_SUCCESS) != null &&
	      ((Boolean)request.getAttribute(IActionConstants.FWD_SUCCESS)) ) { %>
	    <td>&nbsp;&nbsp;&nbsp;</td>
	    <td><button onclick="showZplModal();return false;">Show Label Simulation</button></td>
<% } %>
	</tr>
</table>

<!-- ZPL Display Modal -->
<div id="zpl-modal" class="sample-modal modal hide fade">
    <div class="modal-header">
	   	<button type="button"
	   			class="close"
	   			data-dismiss="modal">&times;</button>
		<h3>Label Simulation Display</h3>
    </div>
    <div class="modal-body">
    	<h5>Master Label(s)</h5>
    	<div id="masterStuff"></div>
    	<h5>Item Label(s)</h5>
    	<div id="itemStuff"></div>
    	<h5>Raw Master ZPL</h5>
    	<div id="masterZpl"></div>
    	<h5>Raw Item ZPL</h5>
    	<div id="itemZpl"></div>
     </div>
    <div class="modal-footer">
    	<button id="closeButton"
    		class="btn btn-primary btn-large"
    		data-dismiss="modal"
    	>Close</button>
    </div>
</div>
