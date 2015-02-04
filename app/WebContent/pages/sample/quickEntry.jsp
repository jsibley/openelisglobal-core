<%@ page language="java" contentType="text/html; charset=utf-8" %>
<%@ page import="us.mn.state.health.lims.common.formfields.FormFields.Field,
				 us.mn.state.health.lims.common.action.IActionConstants,
			     us.mn.state.health.lims.common.provider.validation.AccessionNumberValidatorFactory,
			     us.mn.state.health.lims.common.provider.validation.IAccessionNumberValidator,
			     us.mn.state.health.lims.common.formfields.FormFields,
                 us.mn.state.health.lims.common.util.Versioning,
			     us.mn.state.health.lims.common.util.StringUtil,
			     us.mn.state.health.lims.common.util.IdValuePair,
                 us.mn.state.health.lims.sample.util.AccessionNumberUtil,
			     java.util.Calendar,
			     java.util.List"  %>

<%@ taglib uri="/tags/struts-bean"		prefix="bean" %>
<%@ taglib uri="/tags/struts-html"		prefix="html" %>
<%@ taglib uri="/tags/struts-logic"		prefix="logic" %>
<%@ taglib uri="/tags/labdev-view"		prefix="app" %>
<%@ taglib uri="/tags/struts-tiles"     prefix="tiles" %>
<%@ taglib uri="/tags/sourceforge-ajax" prefix="ajax"%>

<bean:define id="formName"		value='<%= (String)request.getAttribute(IActionConstants.FORM_NAME) %>' />
<bean:define id="genericDomain" value='' />
<bean:define id="entryDate" name="<%=formName%>" property="currentDate" />

<%!
	String basePath = "";
	IAccessionNumberValidator accessionNumberValidator;
    boolean useModalSampleEntry = false;
	boolean useSingleNameField = false;
%>
<%
	String path = request.getContextPath();
	basePath = request.getScheme() + "://" + request.getServerName() + ":"	+ request.getServerPort() + path + "/";
	accessionNumberValidator = new AccessionNumberValidatorFactory().getValidator();
	useModalSampleEntry = FormFields.getInstance().useField( Field.SAMPLE_ENTRY_MODAL_VERSION );
	useSingleNameField = FormFields.getInstance().useField(Field.SINGLE_NAME_FIELD);
%>

<link rel="stylesheet" href="css/jquery_ui/jquery.ui.all.css?ver=<%= Versioning.getBuildNumber() %>">
<link rel="stylesheet" href="css/customAutocomplete.css?ver=<%= Versioning.getBuildNumber() %>">

<script type="text/javascript" src="<%=basePath%>scripts/ui/jquery.ui.core.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/ui/jquery.ui.widget.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/ui/jquery.ui.button.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/ui/jquery.ui.position.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/ui/jquery.ui.autocomplete.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/jquery.selectlist.dev.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/customAutocomplete.js?ver=<%= Versioning.getBuildNumber() %>"></script>

<%
//AIS - bugzilla 1463
Calendar cal = Calendar.getInstance();
int currentYear = cal.get(Calendar.YEAR);

//bugzilla 1979 (lightbox for 2 confirm continue messages)
java.util.Locale locale = (java.util.Locale)request.getSession().getAttribute(org.apache.struts.Globals.LOCALE_KEY);
String clinicNA = us.mn.state.health.lims.common.util.resources.ResourceLocator.getInstance().getMessageResources().getMessage(
				  locale, "quick.entry.clinic.name.not.found");

%>

<%--AIS - bugzilla 1463--%>
<input id="currYear" name="currYear" type="hidden" value="<%=currentYear%>" />

<script type="text/javascript">
var validAccessions = new Array();
var tempAccessions = new Array();
var invalidElements = new Array();
var requiredFields = new Array("accessionNumber", "receivedDateForDisplay");
var usePatientInfoModal = true;
var useSampleRejection = false; // Hard-code value since we never want rejection fields displayed in batch entry
var zplData = "";

//bugzilla 1397 renamed to prePageOnLoad so this is called before actionError pops up errors					
function prePageOnLoad()
{
    var accessionNumber = $("accessionNumber");
    accessionNumber.focus();
    $("receivedDateForDisplay").value = '<%=entryDate%>';
    // generate first sample row, if using modal version
    if (<%=useModalSampleEntry%> && $("samplesAddedTable").rows.length == 1) {
    	addEmptySampleRow("notDirty");
   		$jq("#addSampleButton").attr("disabled", false);
    }

    setSave();
}

function isFieldValid(fieldname)
{
    return $jq.inArray(fieldname, invalidElements) == -1;
}

function setFieldInvalid(field)
{
    if( $jq.inArray(field, invalidElements) == -1 )
    {
        invalidElements.push(field);
    }
}

function setFieldValid(field)
{
    var removeIndex = $jq.inArray(field, invalidElements);
    if( removeIndex != -1 )
    {
    	invalidElements.splice(removeIndex, 1);
    }
}

//disable or enable save button based on validity of fields
function setSave() 
{
	var validToSave = isSaveEnabled() && requiredFieldsValid() && sampleAddValid(true);

	//disable or enable save button based on validity/visibility of fields
	$("saveButtonId").disabled = !validToSave;

	<% if (useModalSampleEntry) { %>
	//disable or enable print button based on validity/visibility of fields
	$('printButton').disabled = !isPrintEnabled();
	<% } %>
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

function isSaveEnabled() 
{
    return invalidElements.length == 0;
}

function  /*void*/ savePage()
{
	<% if (!useModalSampleEntry) { %>
	loadSamples();
	<% } else { %>
	loadXml(); //in sampleAddModal tile
	<% } %>
	fillAccessionList();
  
	// Clear any forced placeholder values before form submission
	$jq('input[placeholder]').each(function() {
		var input = $jq(this);
    	if (input.val() == input.attr('placeholder')) {
			input.val('');
		}
	});

	window.onbeforeunload = null; // Added to flag that formWarning alert isn't needed.
	var form = window.document.forms[0];
	form.action = "QuickEntrySave.do";
	form.submit();
}

function  /*void*/ processValidateEntryDateSuccess(xhr){

    //alert(xhr.responseText);
	var message = xhr.responseXML.getElementsByTagName("message").item(0).firstChild.nodeValue;
	var formField = xhr.responseXML.getElementsByTagName("formfield").item(0).firstChild.nodeValue;

	var isValid = message == "<%=IActionConstants.VALID%>";

	//utilites.js
	selectFieldErrorDisplay( isValid, $(formField));
	setSampleFieldValidity( isValid, formField );
	//setValidIndicaterOnField(isValid, formField);
	setSave();
	setPatientModalSave();
	
	if( message == '<%=IActionConstants.INVALID_TO_LARGE%>' ){
		alert( "<bean:message key="error.date.inFuture"/>" );
	}else if( message == '<%=IActionConstants.INVALID_TO_SMALL%>' ){
		alert( "<bean:message key="error.date.inPast"/>" );
	}
	
	if (!isValid) $(formField).focus();
}


function checkValidEntryDate(date)
{
	if(!date.value || date.value == ""){
		selectFieldErrorDisplay( true, date);
		setSampleFieldValidity( true, date.id );
		setSave();
		setPatientModalSave();
		return;
	}
	//ajax call from utilites.js
	isValidDate( date.value, processValidateEntryDateSuccess, date.id, "past" );
}

function checkValidEntryTime(time)
{
	if(!time.value || time.value == ""){
		selectFieldErrorDisplay( true, time);
		setSampleFieldValidity( true, time.id );
		setSave();
		return;
	}

	var isValid = /^([01]?\d|2[0-3]):[0-5]\d$/.test(time.value);
	selectFieldErrorDisplay( isValid, time);
	setSampleFieldValidity( isValid, time.id );
	setSave();
}

function checkValidEntryAge(age)
{
    if(!age.value || age.value == ""){
		selectFieldErrorDisplay( true, age);
		setSampleFieldValidity( true, age.id );
		setSave();
		setPatientModalSave();
		return;
	}

	var isValid = /^\s*([0-9]|[1-9][0-9]|1[0-4][0-9]|150)\s*$/.test(age.value);
	selectFieldErrorDisplay( isValid, age);
	setSampleFieldValidity( isValid, age.id );
	setSave();
	setPatientModalSave();
}

function processAccessionSuccess(xhr)
{
	//alert(xhr.responseText);
	var formField = xhr.responseXML.getElementsByTagName("formfield").item(0);
	var message = xhr.responseXML.getElementsByTagName("message").item(0).firstChild.nodeValue;
	var success = false;

	if (message == "valid" || message == "SAMPLE_NOT_FOUND"){
		success = true;
	}
	var labElement = formField.firstChild.nodeValue;
	selectFieldErrorDisplay( success, $(labElement));
	if (success) setFieldValid(labElement);
	else setFieldInvalid(labElement);

	if( !success ){
		alert( "<bean:message key="sample.entry.invalid.accession.number"/>" );
		$(labElement).focus();
		updateAccessionCount();
	}
	if (labElement == "accessionNumber") validateAccessionNumber2($('accessionNumber2'));
	if (labElement == "accessionNumber2") validateAccessionRange();

	setSave();
}

function checkAccessionNumber( accessionNumber )
{
	//check if empty
	if ( !fieldIsEmptyById( accessionNumber.id ) )
	{
		validateAccessionNumberOnServer(true, false, accessionNumber.id, accessionNumber.value, processAccessionSuccess, processFailure );
	}
	else
	{
		if (accessionNumber.name != 'accessionNumber2') {
			selectFieldErrorDisplay(false, accessionNumber);
			setFieldInvalid(accessionNumber.id);
			alert("<bean:message key="quick.entry.accession.number.required"/>");
			accessionRangeErrorMessage(false);
			accessionNumber.focus();
		} else {
			if (fieldIsEmptyById(accessionNumber.id)) {
				selectFieldErrorDisplay(true, accessionNumber);
				setFieldValid(accessionNumber.id);
			} else {
				selectFieldErrorDisplay(false, accessionNumber);
				setFieldInvalid(accessionNumber.id);				
			}
		}
	}
	setSave();
}

function validateAccessionRange() {
	var a1 = $('accessionNumber').value;
	var a2 = $('accessionNumber2').value;
	validAccessions = [];
	tempAccessions = [];

	if (a1 != null && a1 != '' && isFieldValid('accessionNumber') && isFieldValid('accessionNumber2')) validAccessions.push(parseInt(a1));
	if (a2 != null && a2 != '' && isFieldValid('accessionNumber') && isFieldValid('accessionNumber2')) {
		if (a2 < a1) {
			selectFieldErrorDisplay(false, $('accessionNumber2'));
			setFieldInvalid('accessionNumber2');
			alert( "<bean:message key="quick.entry.accession.number.bad.order"/>" );
			$('accessionNumber2').focus();
			validAccessions = [];
		} else if (a2 > a1 && a1 != null && a1 != '') {
			accessionRangeErrorMessage(false);
			$jq(invalidElements).each(function(index, value){
				if (value.substring(0, 14) == "tempAccession-")
					setFieldValid(value);
			});
			var ind = 0;
			for (var i = parseInt(a1) + 1; i < parseInt(a2); i++) {
				tempAccessions[ind] = i;
				validateAccessionNumberOnServer(true, false, 'tempAccession-' + ind, i, processAccessionRangeSuccess, processFailure );
				ind++;
			}
			validAccessions.push(parseInt(a2));
		}
	}
	updateAccessionCount();
}

function updateAccessionCount() {
	if (validAccessions.length > 0) {
		$('accessionTotal').innerHTML = '(' + validAccessions.length + ' <bean:message key="quick.entry.accession.number.total"/>)';
		$('accessionTotal').style.display = 'inline';
	} else {
		$('accessionTotal').innerHTML = '&nbsp;';
		$('accessionTotal').style.display = 'none';
	}
}

function accessionRangeErrorMessage(flag) {
	if (flag) {
		$("accessionRangeError").innerHTML = "<span style=\"font-size:.75em;color:red;\">&nbsp;<bean:message key="quick.entry.accession.range.error"/></span>";
		$("accessionRangeError").style.display = 'inline';
	} else {
		$("accessionRangeError").innerHTML = '&nbsp;';
		$("accessionRangeError").style.display = 'none';
	}
}

function processAccessionRangeSuccess(xhr)
{
	//alert(xhr.responseText);
	var formField = xhr.responseXML.getElementsByTagName("formfield").item(0);
	var message = xhr.responseXML.getElementsByTagName("message").item(0);
	var index = parseInt(formField.firstChild.nodeValue.substring(14));

	if (message.firstChild.nodeValue == "valid" || message.firstChild.nodeValue == "SAMPLE_NOT_FOUND") {
		validAccessions.push(parseInt(tempAccessions[index]));
	} else {
		alert( tempAccessions[index] + ": <bean:message key="sample.entry.invalid.accession.number.used"/>" );
		setFieldInvalid("tempAccession-" + index.toString());
		accessionRangeErrorMessage(true);
	}
	updateAccessionCount();
	setSave();
}

function setSampleFieldValidity( valid, fieldId ){

	if( valid )
	{
		setFieldValid(fieldId);
	}
	else
	{
		setFieldInvalid(fieldId);
	}
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

function validateAccessionNumber(field) {
	makeDirty();
	checkAccessionNumber(field);
}

function validateAccessionNumber2(field) {
	makeDirty();
	//only validate if not blank (this is not a required field)
	if (field.value != null && field.value != '') {
	  //if applicable check to make sure 2nd accessionNumber is > first
	    if ($F("accessionNumber") == null || $F("accessionNumber") == '' ||
	    	field.value <= $F("accessionNumber")) {
			selectFieldErrorDisplay(false, field);
			setFieldInvalid(field.id);
			alert( "<bean:message key="quick.entry.accession.number.bad.order"/>" );
			field.focus();
	      	setSave();
	      	return;	
	    }
		checkAccessionNumber(field);
	} else {
		field.value = '';
		selectFieldErrorDisplay(true, field);
		setFieldValid(field.id);
		accessionRangeErrorMessage(false);
		validateAccessionRange();
      	setSave();
	}
}

function fillAccessionList() {
	$("accessionList").value = validAccessions.sort().join(",");
}

function validateOrganizationLocalAbbreviation() {
    new Ajax.Request (
           'ajaxXML',  //url
             {//options
              method: 'get', //http method
              parameters: 'provider=OrganizationLocalAbbreviationValidationProvider&form=' + document.forms[0].name +'&field=submitterNumber&id=' + escape($F("submitterNumber")),      //request parameters
              //indicator: 'throbbing'
              onSuccess:  processValidateOrganizationLocalAbbreviationSuccess,
              onFailure:  processFailure
             }
          );
}

function processValidateOrganizationLocalAbbreviationSuccess(xhr) {
	var message = xhr.responseXML.getElementsByTagName("message").item(0);
	var success = false;
	var field = $('submitterNumber');

	if (message.firstChild.nodeValue.substring(0,5) == "valid"){
		success = true;
	}

	if( !success ){
		$('clinicName').innerHTML = '<%=clinicNA%>';
		selectFieldErrorDisplay(false, field);
		setFieldInvalid(field.id);
		alert("<bean:message key="error.organization.unknown"/>");
		field.focus();
	} else {
		$('clinicName').innerHTML = message.firstChild.nodeValue.substring(5);
		selectFieldErrorDisplay(true, field);
		setFieldValid(field.id);
	}
}

function setMyCancelAction(form, action, validate, parameters)
{
    //first turn off any further validation
    setAction(window.document.forms[0], 'Cancel', 'no', '');
}

function validateProjectIdOrName(field) {
	if ($F(field) == '' || $F(field) == null) {
		selectFieldErrorDisplay(true, field);
		setSampleFieldValidity(true, field.id);
		$(field.id + 'Display').innerHTML = "";
		$(field.id + 'Other').value = "";
		setSave();
 	} else {
 		new Ajax.Request (
           	'ajaxXML',  //url
             	{//options
              	method: 'get', //http method
              	parameters: 'provider=ProjectIdOrNameValidationProvider&field=' + field.id + '&id=' + encodeURIComponent($F(field)),      //request parameters
              	//indicator: 'throbbing'
              	onSuccess:  processProjectIdOrNameSuccess,
              	onFailure:  processFailure
             	}
          	);
 	}
}

function processProjectIdOrNameSuccess(xhr) {
	var formField = xhr.responseXML.getElementsByTagName("formfield").item(0).firstChild.nodeValue;
	var message = xhr.responseXML.getElementsByTagName("message").item(0).firstChild.nodeValue;
	var success = false;

	if (message.substring(0,5) == "valid"){
		success = true;
	}

	selectFieldErrorDisplay( success, $(formField));
	setSampleFieldValidity( success, formField );

	if(success) {
		$(formField + 'Display').innerHTML = message.substring(5);
		$(formField + 'Other').value = message.substring(5);
	} else {
		$(formField + 'Display').innerHTML = "";
		$(formField + 'Other').value = "";
	}
	setSave();
}

function processFailure(xhr) {
  	//ajax call failed
}

function showHideSection(button, targetId){
    if( button.value == "+" ){
        showSection(button, targetId);
    }else{
        hideSection(button, targetId);
    }
}

function showSection( button, targetId){
    $jq("#" + targetId ).show();
    button.value = "-";
}

function hideSection( button, targetId){
    $jq("#" + targetId ).hide();
    button.value = "+";
}

function setPatientModalSave() {
	makeDirty();
	$jq("#patientInfo-save").attr("disabled", false);
	$jq("[id^='patientDob_'],[id^='patientAge_']").each(function() {
		if (!isFieldValid ($jq(this).attr("id"))) {
			$jq("#patientInfo-save").attr("disabled", true);
		}
	});
}

function cancelPatientInfo() {
	if ($jq("#modalPatientInfo").data("modalUpdated")) {
		$jq("#confirm-modal .confirm-close").unbind("click").click(function() {
			cancelConfirm($jq("#modalPatientInfo"));
		});
		$jq("#modalPatientInfo").modal('hide');
		$jq("#confirm-modal").modal('show');
	}
	setSave();
}

function populatePatientInfoModal() {
	if (validAccessions.length < 1) return;
	removeUnusedPatientInfoRows();
	validAccessions.sort(function (a,b) { return a - b; });
	var accCnt = validAccessions.length;
	for (var i = 0; i < accCnt; i++) {
		if ($jq('#patientRow_' + validAccessions[i]).length) {
			continue;
		}
		addPatientInfoRow(validAccessions[i]);
	}
	sortAndAlternateRowColors("patientInfoTable", "#f9f9f9");
	$jq('#modalPatientInfo').modal('show');
}

function sortAndAlternateRowColors(name, color) {
	var table = $jq('#' + name);
	var rows = $jq('tr:gt(0)', table);
	rows.sort(function(a, b) {
	    var keyA = $jq(a).attr('id').substring($jq(a).attr('id').indexOf('_') + 1);
	    var keyB = $jq(b).attr('id').substring($jq(b).attr('id').indexOf('_') + 1);
	    return keyA - keyB;
	});
	removeAllPatientInfoRows();
	$jq.each(rows, function() {
		$jq(table).append($jq(this));
	});

	$jq(table).find("tr:even").css("background-color", color);
}

function removeAllPatientInfoRows() {
	$jq("#patientInfoTable").find("tr:gt(0)").remove();
}

function removeUnusedPatientInfoRows() {
	$jq("#patientInfoTable").find("tr:gt(0)").each(function() {
		if ($jq.inArray(parseInt($jq(this).attr("id").substring($jq(this).attr("id").indexOf('_') + 1), 10), validAccessions) == -1) {
			$jq(this).remove();
		}
	});
}

function addPatientInfoRow(accNo) {
	// duplicate patient info row template, update all ids
	$jq("#patientRow_patientTmpl").clone().find("a, button, div, i, input, label, select, span, td").each(function() {
		if ($jq(this).attr("id") != null) {
			$jq(this).val('').attr('id', function(_, id) { return id.substring(0, id.indexOf('_')) + '_' + accNo; });
			if ($jq(this).attr("id").substring(0, $jq(this).attr("id").indexOf('_')) == "accNo")
				$jq(this).html(accNo);
		}
	}).end().attr("id", function(_, id) { return id.substring(0, id.indexOf('_')) + '_' + accNo; }).appendTo("#patientInfoTable");
}

function savePatients() {
	var xml = convertPatientsToXml();
	$("patientXML").value = xml;
}

function convertPatientsToXml(){
	var rows = $("patientInfoTable").rows;

	var xml = "<?xml version='1.0' encoding='utf-8'?><patients>";

	for( var i = 1; i < rows.length; i++ ){
		xml = xml + convertPatientToXml( rows[i].id.substring($jq(rows[i]).attr('id').indexOf('_')) );
	}

	xml = xml + "</patients>";

	return xml;
}

function convertPatientToXml( id ){
	var refID = $jq("#referringID" + id);
	var pidID = $jq("#patientID" + id);
	var fnameID = $jq("#patientFirstName" + id);
	var lnameID = $jq("#patientLastName" + id);
	var dobID = $jq("#patientDob" + id);
	var ageID = $jq("#patientAge" + id);
	var sexID = $jq("#patientGender" + id);
	var xml = "";
	
    if ((refID.length && $jq.trim(refID.val()).length !== 0) ||
    	(pidID.length && $jq.trim(pidID.val()).length !== 0) ||
    	(fnameID.length && $jq.trim(fnameID.val()).length !== 0) ||
    	(lnameID.length && $jq.trim(lnameID.val()).length !== 0) ||
    	(dobID.length && $jq.trim(dobID.val()).length !== 0) ||
    	(ageID.length && $jq.trim(ageID.val()).length !== 0) ||
    	(sexID.length && $jq.trim(sexID.val()).length !== 0)) {
    	xml = "<patient accNo='" + id.substring(1) +
		  	  "' patientDob='" + dobID.val() +
		  	  "' patientAge='" + ageID.val() +
		  	  "' patientGender='" + sexID.val() + "'>" +
		  	  "<referringID>" + refID.val().escapeHTML() + "</referringID>" +
		  	  "<patientID>" + pidID.val().escapeHTML() + "</patientID>" +
		  	  "<patientFirstName>" + fnameID.val().escapeHTML() + "</patientFirstName>";
		<% if (!useSingleNameField) { %>
		xml += "<patientLastName>" + lnameID.val().escapeHTML() + "</patientLastName>";
		<% } else { %>
		xml += "<patientLastName/>";
		<% } %>
		xml += "</patient>";
	}
    
	return xml;
}

function checkValidTime(time, blankAllowed)
{
    var lowRangeRegEx = new RegExp("^[0-1]{0,1}\\d:[0-5]\\d$");
    var highRangeRegEx = new RegExp("^2[0-3]:[0-5]\\d$");

    if (time.value.blank() && blankAllowed == true) {
    	time.value = "";
        selectFieldErrorDisplay(true, time);
        setSampleFieldValidity(true, time.id);
        setSave();
        return;        
    }

    if( lowRangeRegEx.test(time.value) ||
        highRangeRegEx.test(time.value) ) {
        if( time.value.length == 4 ) {
            time.value = "0" + time.value;
        }
        selectFieldErrorDisplay(true, time);
        setSampleFieldValidity(true, time.id);
    } else {
        selectFieldErrorDisplay(false, time);
        setSampleFieldValidity(false, time.id);
    }

    setSave();
}

function getCurrentTime(){
	var date = new Date();

	return (formatToTwoDigits(date.getHours()) + ":"  + formatToTwoDigits(date.getMinutes()));
}

function formatToTwoDigits( number ){
	return number > 9 ? number : "0" + number;
}
</script>

<!-- Modal code here -->		
<script type="text/javascript">
$jq(document).ready(function () {
			
	// Modal definitions
	$jq('#modalPatientInfo').modal({  // TEMP FOR LABEL PRINT SIMULATION
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
	
	$jq("#cancel-patientInfo").click(function() {
		cancelPatientInfo();
	});

	new AjaxJspTag.Autocomplete(
		"ajaxAutocompleteXML", {
		source: "projectIdOrName",
		target: "projectIdOrNameOther",
		minimumCharacters: "1",
		className: "autocomplete",
		parameters: "projectName={projectIdOrName},provider=ProjectAutocompleteProvider,fieldName=projectName,idName=id"
	});
});
</script>

<html:hidden property="currentDate" name="<%=formName%>" styleId="currentDate"/>
<html:hidden property="accessionList" name="<%=formName%>" value="" styleId="accessionList"/>

<div style="padding-left:80%" id="printForm">
<button name="printRequestForm"
		type="button"
		onclick="window.print();return false;"><bean:message key="label.button.printRequestForm" /></button>
</div>

<table style="width:90%">
	<%--bgm - bugzilla 1665 moved recieved.date here to be the first row above accn # --%>
	<tr> 
		<td>
			<%=StringUtil.getContextualMessageForKey("quick.entry.received.date")%>:<span class="requiredlabel">*</span>
			<font size="1"><bean:message key="sample.date.format" /></font>
		</td>
		<td> 
			<table style="border-collapse:collapse;padding:0px">
				<tr>
					<td>
						<app:text name="<%=formName%>"
								  property="receivedDateForDisplay"
								  onchange="checkValidEntryDate(this);makeDirty()"
								  size="25"
								  maxlength="10"
								  styleClass="text"
								  styleId="receivedDateForDisplay"/>
					</td>
					<td style="padding-left:5px;padding-right:8px">
						<bean:message key="sample.receptionTime"/>:
   				     	<html:text name="<%=formName %>"
    			               	   property="receivedTime"
      			             	   styleId="receivedTime"
      			             	   styleClass="input-mini"
       			            	   maxlength="5"
       			            	   onblur="checkValidTime(this, true);"/>
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td>
			<bean:message key="quick.entry.submitter.number"/>:
		</td>
		<td>
			<table style="border-collapse:collapse;padding:0px">
				<tr>
					<td>
						<app:text name="<%=formName%>"
								  property="submitterNumber"
								  onchange="validateOrganizationLocalAbbreviation();makeDirty()"
								  size="25"
			  					  maxlength="25"
								  styleClass="text"
								  styleId="submitterNumber"/>
					</td>
					<td style="padding-left:5px;padding-right:8px">
						<bean:message key="quick.entry.clinic.name"/>:
						<div id="clinicName" style="display: inline;color: black;"></div>
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td>
			<bean:message key="quick.entry.project.number"/>:
		</td>
		<td> 
			<table style="border-collapse:collapse;padding:0px">
				<tr>
					<td>
						<app:text name="<%=formName%>" 
					  			  property="projectIdOrName" 
	  				  			  onblur="this.value=this.value.toUpperCase();validateProjectIdOrName(this);"
	  				  			  onchange="makeDirty();"
					  			  size="25"
					  			  maxlength="50"
	  				  			  styleClass="text" 
					  			  styleId="projectIdOrName"/>
					</td>
					<td style="padding-left:5px;padding-right:8px">
						<div id="projectIdOrNameDisplay" style="display: inline;color: black;"></div>
						<html:hidden property="projectIdOrNameOther" name="<%=formName%>" styleId="projectIdOrNameOther" />
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td style="min-width: 200px;">
			<%=StringUtil.getContextualMessageForKey("quick.entry.accession.number")%>:<span class="requiredlabel">*</span>
			<div id="accessionTotal" style="font-size:.75em;display:none;">&nbsp;</div><br/>
			<div id="accessionRangeError" style="display:none;">&nbsp;</div>
		</td>
		<%--AIS:bugzilla 1463 added maxlength--%> 
		<td>
			<table style="border-collapse:collapse;padding:0px">
				<tr>
					<td>
						<app:text name="<%=formName%>" 
								  property="accessionNumber" 
								  onchange="validateAccessionNumber(this)" 
								  size="25" 
								  maxlength="<%= Integer.toString(accessionNumberValidator.getMaxAccessionLength())%>"
								  styleClass="text" 
								  styleId="accessionNumber"/>
					</td>
					<td style="padding-left:5px;padding-right:8px">
   		    			<bean:message key="quick.entry.accession.number.thru"/>
					</td>
					<td>
						<app:text name="<%=formName%>" 
								  property="accessionNumber2" 
								  onchange="validateAccessionNumber2(this)" 
								  size="25" 
								  maxlength="<%= Integer.toString(accessionNumberValidator.getMaxAccessionLength())%>"
								  styleClass="text" 
								  styleId="accessionNumber2"/>
					</td>
					<% if (useModalSampleEntry) { %>
					<td style="padding-left:25px; padding-bottom:8px;">
						<button data-toggle="modal"
								id="printMasterLabels"
								name="printMasterLabels"
								type="button"
								onclick="setupPrintLabelsModal($('accessionNumber'), $('accessionNumber2'));$jq('#label-modal').modal('show');"
						><bean:message key="label.button.printMasterLabels" /></button>
					</td>
					<% } %>
				</tr>
			</table>
		</td>
	</tr>
</table>

<table style="display: none">
	<!-- Begin empty patient info row template -->
	<tr id="patientRow_patientTmpl">
		<td><span id="accNo_patientTmpl"></span></td>
		<td><input type="text" maxlength="30" class="input-small"
				   id="referringID_patientTmpl"
				   onchange='$jq("#modalPatientInfo").data("modalUpdated", true);'></td>
		<td><input type="text" maxlength="255" class="input-small"
				   id="patientID_patientTmpl"
				   onchange='$jq("#modalPatientInfo").data("modalUpdated", true);'></td>
		<% if (useSingleNameField) { %>
		<td><input type="text" maxlength="255" class="input-large"
				   id="patientFirstName_patientTmpl"
				   onchange='$jq("#modalPatientInfo").data("modalUpdated", true);'></td>
		<% } else { %>
		<td><input type="text" maxlength="255" class="input-small"
				   id="patientLastName_patientTmpl"
				   onchange='$jq("#modalPatientInfo").data("modalUpdated", true);'></td>
		<td><input type="text" maxlength="255" class="input-small"
				   id="patientFirstName_patientTmpl"
				   onchange='$jq("#modalPatientInfo").data("modalUpdated", true);'></td>
		<% } %>
		<td><input type="text" maxlength="10" class="input-small"
				   id="patientDob_patientTmpl"
				   onchange='checkValidEntryDate(this);$jq("#modalPatientInfo").data("modalUpdated", true);'></td>
		<td><input type="text" maxlength="3" class="input-mini"
				   id="patientAge_patientTmpl"
				   onchange='checkValidEntryAge(this);$jq("#modalPatientInfo").data("modalUpdated", true);'></td>
		<td>
			<app:select name='<%=formName%>'
						 property="patientGender"
						 onchange="$jq('#modalPatientInfo').data('modalUpdated', true);"
						 styleClass="input-small"
						 styleId="patientGender_patientTmpl">
				<app:optionsCollection name='<%=formName%>' property="genderList" label="value" value="id" />
			</app:select>
		</td>
	</tr>
	<!--  End empty patient info row template -->
</table>

<br />
<!--  Sample Add Tile (either modal or non-modal version) -->
<% if (useModalSampleEntry) { %>
<div id="sampleAddModal">
	<tiles:insert attribute="addSampleModal"/>
</div>
<% } else { %>
<hr style="width:100%;height:5px" />
<input type="button" name="showHide" value="+" onclick="showHideSection(this, 'samplesDisplay');" id="samplesSectionId">
<%= StringUtil.getContextualMessageForKey("sample.entry.sampleList.label") %>
<span class="requiredlabel">*</span>
<div id="samplesDisplay" class="colorFill" style="display:none;" >
    <tiles:insert attribute="addSample"/>
</div>
<% } %>

<!-- Patient info modal definition -->			
<div id="modalPatientInfo" class="modal hide fade sample-modal">
	<div class="modal-header">
		<button type="button"
				onclick="cancelPatientInfo();"
				class="close"
				data-dismiss="modal">&times;</button>
		<h3><bean:message key="quick.entry.add.patient.info" /></h3>
	</div>
	<div class="modal-body">
		<div class="row-fluid">
			<div class="span12">
				<table id="patientInfoTable" class="table table-bordered">
					<tr>
						<th><bean:message key="quick.entry.accession.number" /></th>
						<th><bean:message key="sample.clientReference" /></th>
						<th><bean:message key="patient.externalId" /></th>
						<% if (useSingleNameField) { %>
						<th><bean:message key="patient.epiFullName" /></th>
						<% } else { %>
						<th><bean:message key="patient.epiLastName" /></th>
						<th><bean:message key="patient.epiFirstName" /></th>
						<% } %>
						<th><bean:message key="patient.birthDate" /><br/><bean:message key="sample.date.format" /></th>
						<th><bean:message key="patient.age" /></th>
						<th><bean:message key="patient.gender" /></th>
					</tr>
				</table>
			</div>
		</div>
	</div>
	<div class="modal-footer">
		<button class="btn btn-primary btn-large"
				data-dismiss="modal"
				id="patientInfo-save"><bean:message key="label.button.save" /></button>
		&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
		<button class="btn btn-small"
				data-dismiss="modal"
				id="cancel-patientInfo"><bean:message key="label.button.cancel" /></button>
	</div>
</div>

<html:hidden name="<%=formName%>" property="patientXML"  styleId="patientXML"/>
