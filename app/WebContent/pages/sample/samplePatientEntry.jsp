<%@ page import="us.mn.state.health.lims.common.formfields.FormFields.Field"%>
<%@ page language="java" contentType="text/html; charset=utf-8" %>
<%@ page import="us.mn.state.health.lims.common.action.IActionConstants,
                 us.mn.state.health.lims.common.util.SystemConfiguration,
                 us.mn.state.health.lims.common.util.ConfigurationProperties,
                 us.mn.state.health.lims.common.util.ConfigurationProperties.Property,
                 us.mn.state.health.lims.common.provider.validation.IAccessionNumberValidator,
                 us.mn.state.health.lims.common.formfields.FormFields,
                 us.mn.state.health.lims.common.util.Versioning,
                 us.mn.state.health.lims.common.util.StringUtil,
                 us.mn.state.health.lims.common.util.IdValuePair,
                 us.mn.state.health.lims.common.services.PhoneNumberService,
                 us.mn.state.health.lims.sample.bean.SampleOrderItem" %>
<%@ page import="us.mn.state.health.lims.sample.util.AccessionNumberUtil" %>


<%@ taglib uri="/tags/struts-bean"      prefix="bean" %>
<%@ taglib uri="/tags/struts-html"      prefix="html" %>
<%@ taglib uri="/tags/struts-logic"     prefix="logic" %>
<%@ taglib uri="/tags/labdev-view"      prefix="app" %>
<%@ taglib uri="/tags/struts-tiles"     prefix="tiles" %>
<%@ taglib uri="/tags/sourceforge-ajax" prefix="ajax"%>

<bean:define id="formName"      value='<%=(String) request.getAttribute(IActionConstants.FORM_NAME)%>' />
<bean:define id="idSeparator"   value='<%=SystemConfiguration.getInstance().getDefaultIdSeparator()%>' />
<bean:define id="accessionFormat" value='<%= ConfigurationProperties.getInstance().getPropertyValue(Property.AccessionFormat)%>' />
<bean:define id="genericDomain" value='' />
<bean:define id="sampleOrderItems" name='<%=formName%>' property='sampleOrderItems' type="SampleOrderItem" />
<bean:define id="entryDate" name="<%=formName%>" property="currentDate" />


<%!
    String basePath = "";
    boolean useSTNumber = true;
    boolean useMothersName = true;

    boolean useProviderInfo = false;
    boolean patientRequired = false;
    boolean trackPayment = false;
    boolean requesterLastNameRequired = false;
    boolean acceptExternalOrders = false;
    IAccessionNumberValidator accessionNumberValidator;
    boolean useModalSampleEntry = false;
    boolean useRejectionInModalSampleEntry = false;
	boolean supportExternalID = false;
%>
<%
    String path = request.getContextPath();
    basePath = request.getScheme() + "://" + request.getServerName() + ":"  + request.getServerPort() + path + "/";
    useSTNumber =  FormFields.getInstance().useField(FormFields.Field.StNumber);
    useMothersName = FormFields.getInstance().useField(FormFields.Field.MothersName);
    useProviderInfo = FormFields.getInstance().useField(FormFields.Field.ProviderInfo);
    patientRequired = FormFields.getInstance().useField(FormFields.Field.PatientRequired);
    trackPayment = ConfigurationProperties.getInstance().isPropertyValueEqual(Property.TRACK_PATIENT_PAYMENT, "true");
    accessionNumberValidator = AccessionNumberUtil.getAccessionNumberValidator();
    requesterLastNameRequired = FormFields.getInstance().useField(Field.SampleEntryRequesterLastNameRequired);
    acceptExternalOrders = ConfigurationProperties.getInstance().isPropertyValueEqual(Property.ACCEPT_EXTERNAL_ORDERS, "true");
	useModalSampleEntry = FormFields.getInstance().useField( Field.SAMPLE_ENTRY_MODAL_VERSION );
	useRejectionInModalSampleEntry = FormFields.getInstance().useField( Field.SAMPLE_ENTRY_REJECTION_IN_MODAL_VERSION );
 	supportExternalID = FormFields.getInstance().useField(Field.EXTERNAL_ID);
%>


<script type="text/javascript" src="<%=basePath%>scripts/utilities.js?ver=<%= Versioning.getBuildNumber() %>" ></script>

<link rel="stylesheet" href="css/jquery_ui/jquery.ui.all.css?ver=<%= Versioning.getBuildNumber() %>">
<link rel="stylesheet" href="css/customAutocomplete.css?ver=<%= Versioning.getBuildNumber() %>">

<script src="scripts/ui/jquery.ui.core.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script src="scripts/ui/jquery.ui.widget.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script src="scripts/ui/jquery.ui.button.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script src="scripts/ui/jquery.ui.menu.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script src="scripts/ui/jquery.ui.position.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script src="scripts/ui/jquery.ui.autocomplete.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script src="scripts/customAutocomplete.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="scripts/ajaxCalls.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="scripts/laborder.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/jquery.selectlist.dev.js?ver=<%= Versioning.getBuildNumber() %>"></script>


<script type="text/javascript" >

var useSTNumber = <%= useSTNumber %>;
var useMothersName = <%= useMothersName %>;
var requesterLastNameRequired = <%= requesterLastNameRequired %>;
var acceptExternalOrders = <%= acceptExternalOrders %>;
var dirty = false;
var invalidSampleElements = [];
var requiredFields = new Array("labNo", "receivedDateForDisplay" );
var useModalSampleEntry = <%= useModalSampleEntry %>;
var usePatientInfoModal = false;
var useSampleRejection = <%=useRejectionInModalSampleEntry%>;

if( requesterLastNameRequired ){
    requiredFields.push("providerLastNameID");
}
<% if( FormFields.getInstance().useField(Field.SampleEntryUseRequestDate)){ %>
    requiredFields.push("requestDate");
<% } %>
<%  if (requesterLastNameRequired) { %>
    requiredFields.push("providerLastNameID");
<% } %>

function prePageOnLoad()
{
    var accessionNumber = $("labNo");
    accessionNumber.focus();
    
    // generate first sample row, if using modal version of sample entry
    if (useModalSampleEntry && $("samplesAddedTable").rows.length == 1) {
    	addEmptySampleRow("notDirty");
   		$jq("#addSampleButton").attr("disabled", false);
    }

    setSave();
}

function isFieldValid(fieldname)
{
    return invalidSampleElements.indexOf(fieldname) == -1;
}

function setSampleFieldInvalid(field)
{
    if( invalidSampleElements.indexOf(field) == -1 )
    {
        invalidSampleElements.push(field);
    }
}

function setSampleFieldValid(field)
{
    var removeIndex = invalidSampleElements.indexOf( field );
    if( removeIndex != -1 )
    {
        invalidSampleElements.splice( removeIndex,1);
    }
}

function isSaveEnabled()
{
    return invalidSampleElements.length == 0;
}

function submitTheForm(form)
{
    setAction(form, 'Update', 'yes', '?ID=');
}

function  /*void*/ processValidateEntryDateSuccess(xhr){

    //alert(xhr.responseText);
    
    var message = xhr.responseXML.getElementsByTagName("message").item(0).firstChild.nodeValue;
    var formField = xhr.responseXML.getElementsByTagName("formfield").item(0).firstChild.nodeValue;

    var isValid = message == "<%=IActionConstants.VALID%>";

    //utilites.js
    selectFieldErrorDisplay( isValid, $(formField));
    setSampleFieldValidity( isValid, formField );
    setSave();

    if( message == '<%=IActionConstants.INVALID_TO_LARGE%>' ){
        alert( "<bean:message key="error.date.inFuture"/>" );
    }else if( message == '<%=IActionConstants.INVALID_TO_SMALL%>' ){
        alert( "<bean:message key="error.date.inPast"/>" );
    }
}


function checkValidEntryDate(date, dateRange, blankAllowed)
{   
    if((!date.value || date.value == "") && !blankAllowed){
        setSave();
        return;
    } else if ((!date.value || date.value == "") && blankAllowed) {
        setSampleFieldValid(date.id);
        setValidIndicaterOnField(true, date.id);
        return;
    }


    if( !dateRange || dateRange == ""){
        dateRange = 'past';
    }
    
    //ajax call from utilites.js
    isValidDate( date.value, processValidateEntryDateSuccess, date.id, dateRange );
}


function setSampleFieldValidity( valid, fieldName ){

    if( valid )
    {
        setSampleFieldValid(fieldName);
    }
    else
    {
        setSampleFieldInvalid(fieldName);
    }
}


function checkValidTime(time, blankAllowed)
{
    var lowRangeRegEx = new RegExp("^[0-1]{0,1}\\d:[0-5]\\d$");
    var highRangeRegEx = new RegExp("^2[0-3]:[0-5]\\d$");

    if (time.value.blank() && blankAllowed == true) {
        clearFieldErrorDisplay(time);
        setSampleFieldValid(time.name);
        setSave();
        return;        
    }

    if( lowRangeRegEx.test(time.value) ||
        highRangeRegEx.test(time.value) )
    {
        if( time.value.length == 4 )
        {
            time.value = "0" + time.value;
        }
        clearFieldErrorDisplay(time);
        setSampleFieldValid(time.name);
    }
    else
    {
        setFieldErrorDisplay(time);
        setSampleFieldInvalid(time.name);
    }

    setSave();
}

function setMyCancelAction(form, action, validate, parameters)
{
    //first turn off any further validation
    setAction(window.document.forms[0], 'Cancel', 'no', '');
}


function patientInfoValid()
{
    var hasError = false;
    var returnMessage = "";

    if( fieldIsEmptyById("patientID") )
    {
        hasError = true;
        returnMessage += ": patient ID";
    }

    if( fieldIsEmptyById("dossierID") )
    {
        hasError = true;
        returnMessage += ": dossier ID";
    }

    if( fieldIsEmptyById("firstNameID") )
    {
        hasError = true;
        returnMessage += ": first Name";
    }
    if( fieldIsEmptyById("lastNameID") )
    {
        hasError = true;
        returnMessage += ": last Name";
    }


    if( hasError )
    {
        returnMessage = "Please enter the following patient values  " + returnMessage;
    }else
    {
        returnMessage = "valid";
    }

    return returnMessage;
}



function saveItToParentForm(form) {
 submitTheForm(form);
}

function addPatientInfo(  ){
    $("patientInfo").show();
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

function /*bool*/ requiredSampleEntryFieldsValid(){

    if( acceptExternalOrders){ 
        if (missingRequiredValues())
            return false;
    }
        
    for( var i = 0; i < requiredFields.length; ++i ){
        if( $(requiredFields[i]).value.blank() ){
            //special casing
            if( requiredFields[i] == "requesterId" && 
               !( ($("requesterId").selectedIndex == 0)  &&  $("newRequesterName").value.blank())){
                continue;
            }
        return false;
        }
    }
    
    return sampleAddValid( true );
}

function /*bool*/ sampleEntryTopValid(){
    return invalidSampleElements.length == 0 && requiredSampleEntryFieldsValid() && $jq(".error").length == 0;
}

function /*void*/ loadSamples(){
    alert( "Implementation error:  loadSamples not found in addSample tile");
}

function show(id){
    document.getElementById(id).style.visibility="visible";
}

function hide(id){
    document.getElementById(id).style.visibility="hidden";
}


function capitalizeValue( text){
    $("requesterId").value = text.toUpperCase();
}

function checkOrderReferral( value ){

	if (useModalSampleEntry) {
		$jq("#loading-modal").modal('show');
	    getLabOrder(value, processLabOrderSuccess, processGetTestFailure);
	} else {
    	getLabOrder(value, processLabOrderSuccess);
	}
    showSection( $("orderSectionId"), 'orderDisplay');
}

function clearOrderData() {

	if (useModalSampleEntry) {
		resetSampleRows();
	} else {
    	removeAllRows();
    	clearTable(addTestTable);
    	clearTable(addPanelTable);
	}
	removeCrossPanelsTestsTable();
    clearSearchResultTable();
    addPatient();
    clearPatientInfo();
    clearRequester();
	for( var i = 0; i < invalidSampleElements.length; ++i ){
		setValidIndicaterOnField( true, $(invalidSampleElements[i]).name );
	}
	invalidSampleElements = [];
}

function processLabOrderSuccess(xhr){
    //alert(xhr.responseText);

    clearOrderData();

    var message = xhr.responseXML.getElementsByTagName("message").item(0);
    var formField = xhr.responseXML.getElementsByTagName("formfield").item(0);
    var order = formField.getElementsByTagName("order").item(0);

    SampleTypes = [];
    CrossPanels = [];
    CrossTests = [];
    sampleTypeMap = {};

    if( message.firstChild.nodeValue == "valid" ) {
        $jq(".patientSearch").hide();
        var patienttag = order.getElementsByTagName('patient');
        if (patienttag) {
            parsePatient(patienttag);
        }

        var requester = order.getElementsByTagName('requester');
        if (requester) {
            parseRequester(requester);
        }

        var useralert = order.getElementsByTagName("user_alert");
        var alertMessage = "";
        if (useralert) {
            if (useralert.length > 0) {
                alertMessage = useralert[0].firstChild.nodeValue;
                alert(alertMessage);
            }
        }
        var sampletypes = order.getElementsByTagName("sampleType");

        // initialize objects and globals
        sampleTypeOrder = -1;
        crossSampleTypeMap = {};
        crossSampleTypeOrderMap = {};

        parseSampletypes(sampletypes, SampleTypes);
        var crosspanels = order.getElementsByTagName("crosspanel");
        parseCrossPanels(crosspanels, crossSampleTypeMap, crossSampleTypeOrderMap);
        var crosstests = order.getElementsByTagName("crosstest");
        parseCrossTests(crosstests, crossSampleTypeMap, crossSampleTypeOrderMap);

        showSection( $("samplesSectionId"), 'samplesDisplay');
        $("samplesAdded").show();

        notifyChangeListeners();
        testAndSetSave();
   		populateCrossPanelsAndTests(CrossPanels, CrossTests, '<%=entryDate%>');
        displaySampleTypes('<%=entryDate%>');

        if (SampleTypes.length > 0)
             sampleClicked(1);

        if (useModalSampleEntry) {
        	$jq("#loading-modal").modal('hide');
        	if (crosspanels.length > 0 || crosstests.length > 0) {
				$jq("#warning-modal-body-text").text('<%= StringUtil.getMessageForKey("electronic.order.warning.missingSampletype")%>');
    			$jq("#warning-modal").modal('show');
        	}
        }
    } else {
        $jq(".patientSearch").show();
        alert(message.firstChild.nodeValue);
        if (useModalSampleEntry)
        	$jq("#loading-modal").modal('hide');
    }
}

function parsePatient(patienttag) {
    var guidtag = patienttag.item(0).getElementsByTagName("guid");
    var guid;
    if (guidtag) {
        if (guidtag[0].firstChild) {
            guid = guidtag[0].firstChild.nodeValue;
            patientSearch("", "", "", "", "", "", "", guid, "true", processSearchSuccess );
        }       
    }
    
    
}

function clearRequester() {

    $("labNo").value = '';
    $("receivedDateForDisplay").value = '<%=entryDate%>';
    $("receivedTime").value = '';
    <% if( FormFields.getInstance().useField( Field.SAMPLE_ENTRY_USE_REFFERING_PATIENT_NUMBER ) ){%>
    $("referringPatientNumber").value = '';
    <% } %>
	<% if( FormFields.getInstance().useField( Field.PROJECT_OR_NAME ) ){ %>
	$("projectIdOrName").value = '';
	$("projectIdOrNameOther").value = '';
	<% } %>
    <% if( FormFields.getInstance().useField( Field.PROJECT2_OR_NAME ) ){ %>
	$("project2IdOrName").value = '';
	$("project2IdOrNameOther").value = '';
	<% } %>
	<% if( FormFields.getInstance().useField( FormFields.Field.ProviderInfo ) ){ %>
    $("providerFirstNameID").value = '';
    $("providerWorkPhoneID").value = '';
	<% if (!FormFields.getInstance().useField(Field.SINGLE_NAME_FIELD)) { %>
    $("providerLastNameID").value = '';
    <% } %>
	<% if( FormFields.getInstance().useField( Field.SUBMITTER_NUMBER ) ){ %>
	$("submitterNumber").value = '';
	$("clinicName").value = '';
    <% } %>
	<% if (FormFields.getInstance().useField(Field.SAMPLE_ENTRY_REQUESTER_WORK_PHONE_AND_EXT)) { %>
    $("providerWorkPhoneExt").value = '';
	<% } %>
	<% } %>
	<% if (trackPayment) { %>
    $("paymentOptionSelection").value = '';
	<% } %>

}

function parseRequester(requester) {
    var firstName = requester.item(0).getElementsByTagName("firstName");
    var first = "";
    if (firstName.length > 0) {
            first = firstName[0].firstChild.nodeValue;
            $("providerFirstNameID").value = first;
    }
    var lastName = requester.item(0).getElementsByTagName("lastName");
    var last = "";
    if (lastName.length > 0) {
            last = lastName[0].firstChild.nodeValue;
        	<% if (!FormFields.getInstance().useField(Field.SINGLE_NAME_FIELD)) { %>
            $("providerLastNameID").value = last;
            <% } else { %>
            $("providerFirstNameID").value = first.length > 0 ? first + " " + last : last;
            <% } %>
    }
    
    var phoneNum = requester.item(0).getElementsByTagName("providerWorkPhoneID");
    var phone = "";
    if (phoneNum.length > 0) {
        if (phoneNum[0].firstChild) {
            phone = phoneNum[0].firstChild.nodeValue;
            <% if (FormFields.getInstance().useField(Field.SAMPLE_ENTRY_REQUESTER_WORK_PHONE_AND_EXT)) { %>
            if (phone.indexOf(" ") != -1) {
            	$("providerWorkPhoneID").value = phone.substring(0, phone.indexOf(" "));
            	$("providerWorkPhoneExt").value = phone.substring(phone.indexOf(" ") + 1);
            } else {
                $("providerWorkPhoneID").value = phone;
            }
            <% } else { %>
            $("providerWorkPhoneID").value = phone;
            <% } %>
        }
    }
    
    
    
}
function parseSampletypes(sampletypes, SampleTypes) {
        
        var index = 0;
        for( var i = 0; i < sampletypes.length; i++ ) {

            var sampleTypeName = sampletypes.item(i).getElementsByTagName("name")[0].firstChild.nodeValue;
            var sampleTypeId   = sampletypes.item(i).getElementsByTagName("id")[0].firstChild.nodeValue;
            var panels         = sampletypes.item(i).getElementsByTagName("panels")[0];
            var tests          = sampletypes.item(i).getElementsByTagName("tests")[0];
            var sampleTypeInList = getSampleTypeMapEntry(sampleTypeId);
            if (!sampleTypeInList) {
                index++;
                SampleTypes[index-1] = new SampleType(sampleTypeId, sampleTypeName);
                sampleTypeMap[sampleTypeId] = SampleTypes[index-1];
                SampleTypes[index-1].rowid = index;
                sampleTypeInList = SampleTypes[index-1];
                                
                //var addTable = $("samplesAddedTable");
                //var sampleDescription = sampleTypeName;
                //var sampleTypeValue = sampleTypeId;
                //var currentTime = getCurrentTime();
                
                //addTypeToTable(addTable, sampleDescription, sampleTypeValue, currentTime,  '<%=entryDate%>' );
            
            }
            var panelnodes = getNodeNamesByTagName(panels, "panel");
            var testnodes  = getNodeNamesByTagName(tests, "test");
            
            addPanelsToSampleType(sampleTypeInList, panelnodes);
            addTestsToSampleType(sampleTypeInList, testnodes);
           
        }

}

function addPanelsToSampleType(sampleType, panelNodes) {
    for (var i=0; i<panelNodes.length; i++) {
       sampleType.panels[sampleType.panels.length] = panelNodes[i];
    }
}

function addTestsToSampleType(sampleType, testNodes) {
    for (var i=0; i<testNodes.length; i++) {
       sampleType.tests[sampleType.tests.length] = new Test(testNodes[i].id, testNodes[i].name);
    }
}


function parseCrossPanels(crosspanels, crossSampleTypeMap, crossSampleTypeOrderMap) {
        for (var i = 0; i < crosspanels.length; i++ ) {
            var crossPanelName = crosspanels.item(i).getElementsByTagName("name")[0].firstChild.nodeValue;
            var crossPanelId   = crosspanels.item(i).getElementsByTagName("id")[0].firstChild.nodeValue;
            var crossSampleTypes         = crosspanels.item(i).getElementsByTagName("crosssampletypes")[0];
            
            CrossPanels[i] = new CrossPanel(crossPanelId, crossPanelName);
            CrossPanels[i].sampleTypes = getNodeNamesByTagName(crossSampleTypes, "crosssampletype");
            CrossPanels[i].typeMap = new Array(CrossPanels[i].sampleTypes.length);
            if (useModalSampleEntry)
            	CrossPanels[i].testIds = new Array(CrossPanels[i].sampleTypes.length);

            for (var j = 0; j < CrossPanels[i].sampleTypes.length; j = j + 1) {
                CrossPanels[i].typeMap[CrossPanels[i].sampleTypes[j].name] = "t";
                var sampleType = getCrossSampleTypeMapEntry(CrossPanels[i].sampleTypes[j].id);
                
                if (sampleType === undefined) {
                    crossSampleTypeMap[CrossPanels[i].sampleTypes[j].id] = CrossPanels[i].sampleTypes[j];
                    sampleTypeOrder = sampleTypeOrder + 1;
                    crossSampleTypeOrderMap[sampleTypeOrder] = CrossPanels[i].sampleTypes[j].id;
                }

                if (useModalSampleEntry) {
                    var testNode = crossSampleTypes.getElementsByTagName("panelTests")[j];
                    var testIdList = "";
                    var testNameList = "";
                   	var ptNodes = testNode.getElementsByTagName("test");

                   	for (var z = 0; z < ptNodes.length; z++ ) {
						var pName = ptNodes.item(z).getElementsByTagName("name")[0].firstChild.nodeValue;
        	         	if (testNameList.length == 0) {
        	         		testNameList = pName;
        	          	} else {
        	          		testNameList += "," + pName;
        	           	}
        	            var pId = ptNodes.item(z).getElementsByTagName("id")[0].firstChild.nodeValue;
        	           	if (testIdList.length == 0) {
        	           		testIdList = pId;
        	           	} else {
        	           		testIdList += "," + pId;
        	           	}
                    }
                	
                	CrossPanels[i].testIds[CrossPanels[i].sampleTypes[j].id] = testIdList;
                	CrossPanels[i].testNames = testNameList;
                }
            }
        }
} 

function parseCrossTests(crosstests, crossSampleTypeMap, crossSampleTypeOrderMap) {
    for (var x = 0; x < crosstests.length; x = x + 1) {
        var crossTestName = crosstests.item(x).getElementsByTagName("name")[0].firstChild.nodeValue;
   //     var crossTestId   = crosstests.item(x).getElementsByTagName("id")[0].firstChild.nodeValue;
        var crossSampleTypes  = crosstests.item(x).getElementsByTagName("crosssampletypes")[0];
        
        CrossTests[x] = new CrossTest(crossTestName);
        CrossTests[x].sampleTypes = getNodeNamesByTagName(crossSampleTypes, "crosssampletype");
        CrossTests[x].typeMap = new Array(CrossTests[x].sampleTypes.length);    
        var sTypes = [];
        for (var y = 0; y < CrossTests[x].sampleTypes.length; y++) {
        
            //alert(crossTestName + " " + CrossTests[x].sampleTypes[y].id + " testid=" + CrossTests[x].sampleTypes[y].testId);
            sTypes[y] = CrossTests[x].sampleTypes[y];
            CrossTests[x].typeMap[CrossTests[x].sampleTypes[y].name] = "t";
            var sType = getCrossSampleTypeMapEntry(CrossTests[x].sampleTypes[y].id);
            
            if (sType === undefined) {
                crossSampleTypeMap[CrossTests[x].sampleTypes[y].id] = CrossTests[x].sampleTypes[y];
                sampleTypeOrder++;
                crossSampleTypeOrderMap[sampleTypeOrder] = CrossTests[x].sampleTypes[y].id;               
            }
        }
        crossTestSampleTypeTestIdMap[crossTestName] = sTypes;
    }

}

function validatePhoneNumber( phoneElement){
    validatePhoneNumberOnServer( phoneElement, processPhoneSuccess);
}

function  processPhoneSuccess(xhr){
    //alert(xhr.responseText);

    var formField = xhr.responseXML.getElementsByTagName("formfield").item(0);
    var message = xhr.responseXML.getElementsByTagName("message").item(0);
    var success = false;

    if (message.firstChild.nodeValue == "valid"){
        success = true;
    }
    var labElement = formField.firstChild.nodeValue;
    selectFieldErrorDisplay( success, $(labElement));
    setSampleFieldValidity( success, labElement);

    if( !success ){
        alert( message.firstChild.nodeValue );
    }

    setSave();
}
</script>

<!-- This define may not be needed, look at usages (not in any other jsp or js page-->
<html:hidden property="currentDate" name="<%=formName%>" styleId="currentDate"/>
<html:hidden property="sampleOrderItems.newRequesterName" name='<%=formName%>' styleId="newRequesterName" />


<% if( acceptExternalOrders){ %>
<%= StringUtil.getContextualMessageForKey( "referring.order.number" ) %>:
<html:text name='<%=formName %>'
           styleId="externalOrderNumber"
           property="sampleOrderItems.externalOrderNumber"
           onchange="checkOrderReferral(this.value);makeDirty();"/>
<input type="button" name="searchExternalButton" value='<%= StringUtil.getMessageForKey("label.button.search")%>'
       onclick="checkOrderReferral($(externalOrderNumber).value);makeDirty();">
<%= StringUtil.getContextualMessageForKey( "referring.order.not.found" ) %>
<hr style="width:100%;height:5px"/>

<% } %>
            
<div id=sampleEntryPage >
<input type="button" name="showHide" value='<%= acceptExternalOrders ? "+" : "-" %>' onclick="showHideSection(this, 'orderDisplay');" id="orderSectionId">
<%= StringUtil.getContextualMessageForKey("sample.entry.order.label") %>
<span class="requiredlabel">*</span>

<tiles:insert attribute="sampleOrder" />

<hr style="width:100%;height:5px" />
<input type="button" name="showHide" value="+" onclick="showHideSection(this, 'samplesDisplay');" id="samplesSectionId">
<%= StringUtil.getContextualMessageForKey("sample.entry.sampleList.label") %>
<span class="requiredlabel">*</span>

<div id="samplesDisplay" class="colorFill" style="display:none;" >
<% if (useModalSampleEntry) { %>
	<div id="sampleAddModal">
		<tiles:insert attribute="addSampleModal"/>
	</div>
<% } else { %>
    <tiles:insert attribute="addSample"/>
	<br />
<% } %>
</div>

<hr style="width:100%;height:5px" />
<html:hidden name="<%=formName%>" property="patientPK" styleId="patientPK"/>

<table style="width:100%">
    <tr>
        <td style="width:15%;text-align:left">
            <input type="button" name="showHide" value="+" onclick="showHideSection(this, 'patientInfo');" id="patientSectionId">
            <bean:message key="sample.entry.patient" />:
            <% if ( patientRequired ) { %><span class="requiredlabel">*</span><% } %>
        </td>
        <td style="width:15%" id="firstName"><b>&nbsp;</b></td>
        <td style="width:15%">
            <% if(useMothersName){ %><bean:message key="patient.mother.name"/>:<% } %>
        </td>
        <td style="width:15%" id="mother"><b>&nbsp;</b></td>
        <td style="width:10%">
            <% if( useSTNumber){ %><bean:message key="patient.ST.number"/>:<% } else if (supportExternalID) { %><bean:message key="patient.externalId"/>:<% } %>
        </td>
        <td style="width:15%" id=<% if (useSTNumber) { %>"st"<% } else if (supportExternalID) { %>"external"<% } %>><b>&nbsp;</b></td>
        <td style="width:5%">&nbsp;</td>
    </tr>
    <tr>
        <td>&nbsp;</td>
        <td id="lastName"><b>&nbsp;</b></td>
        <td>
            <bean:message key="patient.birthDate"/>:
        </td>
        <td id="dob"><b>&nbsp;</b></td>
        <td>
            <%=StringUtil.getContextualMessageForKey("patient.NationalID") %>:
        </td>
        <td id="national"><b>&nbsp;</b></td>
        <td>
            <bean:message key="patient.gender"/>:
        </td>
        <td id="gender"><b>&nbsp;</b></td>
    </tr>
</table>

<div id="patientInfo"  style="display:none;" >
    <tiles:useAttribute name="displayOrderItemsInPatientManagement" scope="request" />
    <tiles:insert attribute="patientInfo" />
    <tiles:insert attribute="patientClinicalInfo" />
</div>
</div>

<script type="text/javascript" >

//all methods here either overwrite methods in tiles or all called after they are loaded

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

function  /*void*/ savePage()
{
	if (!useModalSampleEntry) {
    	loadSamples(); //in addSample tile
	} else {
		loadXml(); //in sampleAddModal tile
	
		// Clear any forced placeholder values before form submission
		$jq('input[placeholder]').each(function() {
			var input = $jq(this);
    		if (input.val() == input.attr('placeholder')) {
				input.val('');
			}
		});
	}

	<% if (FormFields.getInstance().useField(Field.SAMPLE_ENTRY_REQUESTER_WORK_PHONE_AND_EXT)) { %>
	// Merge requester work phone and extension (space separated) before submission
	if ($('providerWorkPhoneExt').value.length > 0)
		$('providerWorkPhoneID').value = $('providerWorkPhoneID').value + " " + $('providerWorkPhoneExt').value;
	<% } %>
	
  	window.onbeforeunload = null; // Added to flag that formWarning alert isn't needed.
    var form = window.document.forms[0];
    form.action = "SamplePatientEntrySave.do";
    form.submit();
}


function /*void*/ setSave()
{
	var validToSave =  patientFormValid() && sampleEntryTopValid();

	if (useModalSampleEntry) {	
		//disable or enable print button based on validity/visibility of fields
		$('printButton').disabled = !isPrintEnabled();
	}
	
    $("saveButtonId").disabled = !validToSave;
}

//called from patientSearch.jsp
function /*void*/ selectedPatientChangedForSample(firstName, lastName, gender, DOB, stNumber, subjectNumb, nationalID, mother, pk, externalID ){
    patientInfoChangedForSample( firstName, lastName, gender, DOB, stNumber, subjectNumb, nationalID, mother, pk, externalID );
    $("patientPK").value = pk;

    setSave();
}

//called from patientManagment.jsp
function /*void*/ patientInfoChangedForSample( firstName, lastName, gender, DOB, stNumber, subjectNum, nationalID, mother, pk, externalID ){
    setPatientSummary( "firstName", firstName );
    setPatientSummary( "lastName", lastName );
    setPatientSummary( "gender", gender );
    setPatientSummary( "dob", DOB );
    if( useSTNumber){setPatientSummary( "st", stNumber );}
    setPatientSummary( "national", nationalID );
    if( useMothersName){setPatientSummary( "mother", mother );}
    $("patientPK").value = pk;
	if (externalID) { setPatientSummary( "external", externalID); }

    makeDirty();
    setSave();
}

function /*voiid*/ setPatientSummary( name, value ){
    $(name).firstChild.firstChild.nodeValue = value;
}

//overwrites function from patient search
function /*void*/ doSelectPatient(){
/*  $("firstName").firstChild.firstChild.nodeValue = currentPatient["first"];
    $("mother").firstChild.firstChild.nodeValue = currentPatient["mother"];
    $("st").firstChild.firstChild.nodeValue = currentPatient["st"];
    $("lastName").firstChild.firstChild.nodeValue = currentPatient["last"];
    $("dob").firstChild.firstChild.nodeValue = currentPatient["DOB"];
    $("national").firstChild.firstChild.nodeValue = currentPatient["national"];
    $("gender").firstChild.firstChild.nodeValue = currentPatient["gender"];
    $("patientPK").value = currentPatient["pk"];

    setSave();

*/
}
 
var patientRegistered = false;
var sampleRegistered = false;

/* is registered in patientManagement.jsp */
function /*void*/ registerPatientChangedForSampleEntry(){
    if( !patientRegistered ){
        addPatientInfoChangedListener( patientInfoChangedForSample );
        patientRegistered = true;
    }
}

/* is registered in sampleAdd.jsp */
function /*void*/ registerSampleChangedForSampleEntry(){
    if( !sampleRegistered ){
        addSampleChangedListener( makeDirty );
        sampleRegistered = true;
    }
}

registerPatientChangedForSampleEntry();
registerSampleChangedForSampleEntry();

</script>
