<%@ page language="java" contentType="text/html; charset=utf-8"
	import="us.mn.state.health.lims.common.action.IActionConstants,
	        us.mn.state.health.lims.common.formfields.FormFields,
	        us.mn.state.health.lims.common.formfields.FormFields.Field,
			us.mn.state.health.lims.common.provider.reports.SampleLabelPrintProvider,
			us.mn.state.health.lims.common.util.ConfigurationProperties,
			us.mn.state.health.lims.common.util.ConfigurationProperties.Property,
	        us.mn.state.health.lims.common.util.IdValuePair,
            us.mn.state.health.lims.common.util.Versioning,
	        us.mn.state.health.lims.common.util.StringUtil,
	        us.mn.state.health.lims.common.util.SystemConfiguration"%>

<%@ taglib uri="/tags/struts-bean" prefix="bean"%>
<%@ taglib uri="/tags/struts-html" prefix="html"%>
<%@ taglib uri="/tags/struts-logic" prefix="logic"%>
<%@ taglib uri="/tags/labdev-view" prefix="app"%>
<%@ taglib uri="/tags/sourceforge-ajax" prefix="ajax"%>
<%@ taglib uri="/tags/struts-tiles" prefix="tiles" %>

<bean:define id="formName" value='<%=(String) request.getAttribute(IActionConstants.FORM_NAME)%>' />
<bean:define id="entryDate" name="<%=formName%>" property="currentDate" />
<bean:define id="maxLabels" value='<%= SystemConfiguration.getInstance().getMaxNumberOfLabels() %>' />



<%!String path = "";
	String basePath = "";
	boolean useCollectionDate = true;
	boolean useInitialSampleCondition = false;
	boolean useCollector = false;
	boolean autofillCollectionDate = true;
	boolean useSampleSource = false;
	boolean useSampleTypeAutocomplete = false;
	boolean useSampleSourceAutocomplete = false;
	boolean useSpecimenLabels = false;
%>
<%
	path = request.getContextPath();
	basePath = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + path
			+ "/";
	useCollectionDate = FormFields.getInstance().useField(Field.CollectionDate);
	useInitialSampleCondition = FormFields.getInstance().useField(Field.InitialSampleCondition);
	useCollector = FormFields.getInstance().useField(Field.SampleEntrySampleCollector);
	autofillCollectionDate = ConfigurationProperties.getInstance().isPropertyValueEqual(Property.AUTOFILL_COLLECTION_DATE, "true");
	useSampleSource = ConfigurationProperties.getInstance().isPropertyValueEqual(Property.USE_SAMPLE_SOURCE, "true");
	useSampleTypeAutocomplete = ConfigurationProperties.getInstance().isPropertyValueEqual(Property.USE_SAMPLE_TYPE_AUTOCOMPLETE, "true");
	useSampleSourceAutocomplete = ConfigurationProperties.getInstance().isPropertyValueEqual(Property.USE_SAMPLE_SOURCE_AUTOCOMPLETE, "true");
	useSpecimenLabels = ConfigurationProperties.getInstance().isPropertyValueEqual(Property.USE_SPECIMEN_LABELS, "true");
%>

<link rel="stylesheet" media="screen" type="text/css" href="<%=basePath%>css/sampleEntry.css?ver=<%= Versioning.getBuildNumber() %>">
<link rel="stylesheet" media="screen" type="text/css" href="<%=basePath%>css/jquery.asmselect.css?ver=<%= Versioning.getBuildNumber() %>" />

<script type="text/javascript" src="<%=basePath%>scripts/jquery.asmselect.js?ver=<%= Versioning.getBuildNumber() %>"></script>


<script type="text/javascript" >

var useCollectionDate = <%= useCollectionDate %>;
var autoFillCollectionDate = <%= autofillCollectionDate %>;
var useInitialSampleCondition = <%= useInitialSampleCondition  %>;
var useCollector = <%= useCollector %>;
var useSampleSource = <%= useSampleSource %>;
var useSampleTypeAutocomplete = <%= useSampleTypeAutocomplete %>;
var useSampleSourceAutocomplete = <%= useSampleSourceAutocomplete %>;
var sampleTypeField = useSampleTypeAutocomplete ? "typeOfSampleId" : "typeOfSampleDesc";
var sampleSourceField = useSampleSourceAutocomplete ? "sourceOfSampleId" : "sourceOfSampleDesc";
var lastTypeClicked = "";
var currentCheckedType = -1;
var currentTypeForTests = -1;
var selectedRowId = -1;
var labOrderType = "none"; //if set will be done by other tiles
var sampleChangeListeners = [];
var sampleIdStart = 0;
var crossTestSampleRowMap = [];
var crossTestSampleRowPanelIds = [];
var crossTestSampleRowTestIds = [];
var crossTestSampleRowTestNames = [];
var assignSampletypesHeader = '<bean:message key="electronic.order.assign.sampletypes" />';

// this function required if we're included in the sampleEdit page
function samplesHaveBeenAdded(){
	return $("samplesAddedTable").rows.length > 1;
}

// this function required if we're included in the samplePatientEntry page
function sampleAddValid(sampleRequired) {
	var table = $("samplesAddedTable");	
	for (var i = 1; i < table.rows.length; i++) {
		var rowId = parseInt($jq("#samplesAddedTable tr:nth-child(" + (i + 1) + ")").attr("id").substring(1));

        // check if required fields exist
        if (!($jq('#typeOfSampleDesc_' + rowId).length && $jq('#tests_' + rowId).length))
        	return false;
   		// check for empty input values
       	if ($jq.trim($jq('#typeOfSampleDesc_' + rowId).val()).length === 0 || $jq.trim($jq('#tests_' + rowId).html()).length === 0)
           	return false;
    }
    return true;
}

//this function required if we're included in the samplePatientEntry page to allow populating samples from electronic orders, it has no purpose in this tile
function sampleClicked() {
}

//this function required if we're included in the samplePatientEntry page to allow populating samples from electronic orders
function testAndSetSave(){
	if(window.setSave){
		setSave();
	}else if(window.setSaveButton){
		setSaveButton();
	}
}

//this function required if we're included in the samplePatientEntry page to allow populating samples from electronic orders
function addTypeToTable(table, sampleDescription, sampleType, currentTime, currentDate) {
	if ($(table.id).rows.length == 1)
		addEmptySampleRow();
	
	var id = parseInt($jq("#" + table.id + " tr:last").attr("id").substring(1));
	if ($jq("#" + sampleTypeField + "_" + id).val().length > 0) {
		addEmptySampleRow();
		id = parseInt($jq("#" + table.id + " tr:last").attr("id").substring(1));
	}
	
	//set sample type
	$jq("#" + sampleTypeField + "_" + id).val(sampleType);
	if (useSampleTypeAutocomplete)
		$jq("#typeOfSampleDesc_" + id).val(sampleDescription.toUpperCase());

	//set collection date/time
	if (useCollectionDate && autoFillCollectionDate) {
		$jq("#collectionDate_" + id).val(currentDate);
		$jq("#collectionTime_" + id).val(currentTime);
	}
}

//this function required if we're included in the samplePatientEntry page to allow populating samples from electronic orders
function crossTestSelectedModal(crossTestRow, testName, sampleTypeId, sampleTypeName, entryDate) {
	var oldRow = crossTestSampleRowMap[crossTestRow];
	var testId = getTestIdFromNameAndSampleTypeId(testName, sampleTypeId);

	// if this test already added to a sample row, remove it
	if (oldRow !== undefined && oldRow.length) {
		var oldTestId = getTestIdFromNameAndSampleTypeId(testName, $jq("#" + sampleTypeField + "_" + oldRow).val());
		
		removeAddedIdFromSampleRow("Test", crossTestRow, oldTestId);
		removeAddedTestNameFromSampleRow(crossTestRow, testName);
		restoreDataToSampleRow(oldRow, 0, [oldTestId], [testName], $jq.grep(crossTestSampleRowMap, function(n, i) { return (n == oldRow); }).length);

		// remove row if empty
		if ($jq("#testIds_" + oldRow).val().length == 0 && $jq("#panelIds_" + oldRow).val().length == 0)
			if ($jq("#_" + oldRow)[0].sectionRowIndex == 1) {
				removeFirstSampleRow(oldRow);
				if ($("samplesAddedTable").rows.length == 1)
					addEmptySampleRow();
			} else
				removeSampleRow(oldRow);
	}
	
	var table = $("samplesAddedTable");
	var length = table.rows.length;
	var rows = table.rows;
	var currentTime = getCurrentTime();
	var sampleTypeMatchingRowIndexes = [];
	
	// look for any rows that match the selected sampletype for this crossTest
	for( var i = 1; i < length; i++){
		var currentRowSampleTypeId = $jq("#" + sampleTypeField + rows[i].id).val();

		if (sampleTypeId == currentRowSampleTypeId) {
			sampleTypeMatchingRowIndexes[sampleTypeMatchingRowIndexes.length] = i;
			break;
		}
	}

	if (sampleTypeMatchingRowIndexes.length > 0){
		var tempIndex = rows[sampleTypeMatchingRowIndexes[0]].id;
		var crossTests = $("testIds" + tempIndex).value.split(",");
		var crossTestNames = $jq("#tests" + tempIndex).html().split(",");

		addIdToSampleRow("Test", crossTests, tempIndex, testId);
		addTestNameToSampleRow(crossTestNames, tempIndex, testName);
		crossTestSampleRowMap[crossTestRow] = tempIndex.substring(1);
	} else {	// No sampleType row available yet.	
		addTypeToTable(table, sampleTypeName, sampleTypeId, currentTime,  entryDate );
		$("samplesAdded").show();
		table = $("samplesAddedTable");
		length = table.rows.length;
		rows = table.rows;
		var lastRowIndex = length - 1;
		var lastRowId = rows[lastRowIndex].id;

		addIdToSampleRow("Test", [], lastRowId, testId);
		addTestNameToSampleRow([], lastRowId, testName);
    	toggleAssignAndRejectDisabled(lastRowId.substring(1), false);
		crossTestSampleRowMap[crossTestRow] = lastRowId.substring(1);
	}

	$jq("#crossPanelsTestsTable tr:nth-child(" + (crossTestRow + 1) + ") input[type='radio']").each(function(){
		if ($jq(this).val() == sampleTypeId)
			$jq(this).prop("checked", true);
	});
	setRequiredSelected("hidden-" + testName);
}

//this function required if we're included in the samplePatientEntry page to allow populating samples from electronic orders
function crossPanelSelectedModal(crossTestRow, panelId, panelName, sampleTypeId, sampleTypeName, entryDate) {
	var oldRow = crossTestSampleRowMap[crossTestRow];
	var oldTestIds = [];
	var testIds = [];
	var testNames = [];

	for (var i = 0; i < CrossPanels.length; i++) {
		if (CrossPanels[i].id == panelId) {
			if (oldRow !== undefined && oldRow.length)
				oldTestIds = CrossPanels[i].testIds[$jq("#" + sampleTypeField + "_" + oldRow).val()].split(",");
			testIds = CrossPanels[i].testIds[sampleTypeId].split(",");
   			testNames = CrossPanels[i].testNames.split(",");
   			break;
		}
	}

	// if this panel already added to a sample row, remove it along with its tests
	if (oldRow !== undefined && oldRow.length) {
		removeAddedIdFromSampleRow("Panel", crossTestRow, panelId);

		// handle removal of tests
		for (var i = 0; i < testNames.length; i++)
			removeAddedTestNameFromSampleRow(crossTestRow, testNames[i]);
		for (var i = 0; i < oldTestIds.length; i++)
			removeAddedIdFromSampleRow("Test", crossTestRow, oldTestIds[i]);

		restoreDataToSampleRow(oldRow, panelId, oldTestIds, testNames, $jq.grep(crossTestSampleRowMap, function(n, i) { return (n == oldRow); }).length);

		// remove row if empty
		if ($jq("#testIds_" + oldRow).val().length == 0 && $jq("#panelIds_" + oldRow).val().length == 0)
			if ($jq("#_" + oldRow)[0].sectionRowIndex == 1) {
				removeFirstSampleRow(oldRow);
				if ($("samplesAddedTable").rows.length == 1)
					addEmptySampleRow();
			} else
				removeSampleRow(oldRow);
	}
		
	var table = $("samplesAddedTable");
	var length = table.rows.length;
	var rows = table.rows;
	var currentTime = getCurrentTime();
	var sampleTypeMatchingRowIndexes = [];
	
	// look for any row that matches the selected sampletype for this crossPanel
	for( var i = 1; i < length; i++){
		var currentRowSampleTypeId = $jq("#" + sampleTypeField + rows[i].id).val();

		if (sampleTypeId == currentRowSampleTypeId) {
			sampleTypeMatchingRowIndexes[sampleTypeMatchingRowIndexes.length] = i;
			break;
		}
	}

	if (sampleTypeMatchingRowIndexes.length > 0) {
		var tempIndex = rows[sampleTypeMatchingRowIndexes[0]].id;
		var crossPanels = $("panelIds" + tempIndex).value.split(",");
		var crossTests = $("testIds" + tempIndex).value.split(",");
		var crossTestNames = $jq("#tests" + tempIndex).html().split(",");

		addIdToSampleRow("Panel", crossPanels, tempIndex, panelId);
		// handle adding tests
		for (var i = 0; i < testNames.length; i++)
			addTestNameToSampleRow(crossTestNames, tempIndex, testNames[i]);
		for (var i = 0; i < testIds.length; i++)
			addIdToSampleRow("Test", crossTests, tempIndex, testIds[i]);
		crossTestSampleRowMap[crossTestRow] = tempIndex.substring(1);		
	} else {
		addTypeToTable(table, sampleTypeName, sampleTypeId, currentTime,  entryDate );
		$("samplesAdded").show();
		table = $("samplesAddedTable");
		length = table.rows.length;
		rows = table.rows;
		var lastRowIndex = length - 1;
		var lastRowId = rows[lastRowIndex].id;

		addIdToSampleRow("Panel", [], lastRowId, panelId);
		// handle adding tests
		for (var i = 0; i < testNames.length; i++)
			addTestNameToSampleRow($jq("#tests" + lastRowId).html().split(","), lastRowId, testNames[i]);
		for (var i = 0; i < testIds.length; i++)
			addIdToSampleRow("Test", $jq("#testIds" + lastRowId).val().split(","), lastRowId, testIds[i]);
    	toggleAssignAndRejectDisabled(lastRowId.substring(1), false);
		crossTestSampleRowMap[crossTestRow] = lastRowId.substring(1);
	}

	$jq("#crossPanelsTestsTable tr:nth-child(" + (crossTestRow + 1) + ") input[type='radio']").each(function(){
		if ($jq(this).val() == sampleTypeId)
			$jq(this).prop("checked", true);
	});
	setRequiredSelected("hidden-" + panelName);
}

function getTestIdFromNameAndSampleTypeId(testName, sampleTypeId) {
	var sTypes = getCrossTestSampleTypeTestIdMapEntry(testName);
	for (var i=0; i<sTypes.length; i++) {
		if (sTypes[i].id == sampleTypeId) {
			return sTypes[i].testId;
			break;
		}
	}
}

function removeAddedIdFromSampleRow(type, row, id) {
	var existing = $jq("#" + type.toLowerCase() + "Ids_" + crossTestSampleRowMap[row]).val();
	var arrName = "crossTestSampleRow" + type + "Ids";

	$jq("#" + type.toLowerCase() + "Ids_" + crossTestSampleRowMap[row]).val(existing.split(",").filter(function (v) { return v != id; }).join(","));
	if (window[arrName][crossTestSampleRowMap[row]][id] !== undefined && window[arrName][crossTestSampleRowMap[row]][id] > 0)
		window[arrName][crossTestSampleRowMap[row]][id]--;
}

function removeAddedTestNameFromSampleRow(crossTestRow, testName) {
	var currentTestNames = $jq("#tests_" + crossTestSampleRowMap[crossTestRow]).html();
	$jq("#tests_" + crossTestSampleRowMap[crossTestRow]).html(currentTestNames.split(",").filter(function (v) { return v != testName; }).join(","));
	if (crossTestSampleRowTestNames[crossTestSampleRowMap[crossTestRow]][testName] !== undefined && crossTestSampleRowTestNames[crossTestSampleRowMap[crossTestRow]][testName] > 0)
		crossTestSampleRowTestNames[crossTestSampleRowMap[crossTestRow]][testName]--;
}

function restoreDataToSampleRow(row, panelId, testIds, testNames, cnt) {
	// put back any panels/tests that were just deleted but previously in the row
	if (crossTestSampleRowPanelIds[row] !== undefined && panelId > 0) {
		if (crossTestSampleRowPanelIds[row][panelId] !== undefined && crossTestSampleRowPanelIds[row][panelId] > 0) {
			if ($jq("#panelIds_" + row).val().length)
				$jq("#panelIds_" + row).val($jq("#panelIds_" + row).val() + "," + panelId);
			else
				$jq("#panelIds_" + row).val(panelId);
		}
		if (crossTestSampleRowPanelIds[row][panelId] == 1)
			crossTestSampleRowPanelIds[row][panelId]--;
	}
	if (crossTestSampleRowTestIds[row] !== undefined) {
		for (var i = 0; i < testIds.length; i++) {
			if (crossTestSampleRowTestIds[row][testIds[i]] !== undefined && crossTestSampleRowTestIds[row][testIds[i]] > 0) {
				if ($jq("#testIds_" + row).val().length)
					$jq("#testIds_" + row).val($jq("#testIds_" + row).val() + "," + testIds[i]);
				else
					$jq("#testIds_" + row).val(testIds[i]);
			}
			if (crossTestSampleRowTestIds[row][testIds[i]] == 1 && cnt < 2)
				crossTestSampleRowTestIds[row][testIds[i]]--;
		}
	}
	if (crossTestSampleRowTestNames[row] !== undefined) {
		for (var i = 0; i < testNames.length; i++) {
			if (crossTestSampleRowTestNames[row][testNames[i]] !== undefined && crossTestSampleRowTestNames[row][testNames[i]] > 0) {
				if ($jq("#tests_" + row).html().length)
					$jq("#tests_" + row).html($jq("#tests_" + row).html() + "," + testNames[i]);
				else
					$jq("#tests_" + row).html(testNames[i]);
			}
			if (crossTestSampleRowTestNames[row][testNames[i]] == 1 && cnt < 2)
				crossTestSampleRowTestNames[row][testNames[i]]--;
		}
	}
}

function addIdToSampleRow(type, existing, index, id) {
	var increment = 1;
	var arrName = "crossTestSampleRow" + type + "Ids";
	var arrIndex = index.substring(1);

	if (existing.length > 0) {
		if ($jq.inArray("" + id, existing) == -1)
			$(type.toLowerCase() + "Ids" + index).value += ($(type.toLowerCase() + "Ids" + index).value.length > 0 ? "," : "") + id;
		else
			increment = 2;
	} else {
		$(type.toLowerCase() + "Ids" + index).value = id;
	}

	if (window[arrName][arrIndex] !== undefined) {
		if (window[arrName][arrIndex][id] !== undefined && window[arrName][arrIndex][id] > 0)
			window[arrName][arrIndex][id]++;
		else
			window[arrName][arrIndex][id] = increment;
	} else {
		window[arrName][arrIndex] = {};
		window[arrName][arrIndex][id] = increment;
	}
}

function addTestNameToSampleRow(crossTestNames, tempIndex, testName) {
	var increment = 1;
	var arrIndex = tempIndex.substring(1);

	if (crossTestNames.length > 0) {
		if ($jq.inArray(testName, crossTestNames) == -1)
			$jq("#tests" + tempIndex).html($jq("#tests" + tempIndex).html() + ($jq("#tests" + tempIndex).html().length > 0 ? "," : "") + testName).show();
		else
			increment = 2;
	} else {
		$jq("#tests" + tempIndex).html(testName).show();
	}

	if (crossTestSampleRowTestNames[arrIndex] !== undefined) {
		if (crossTestSampleRowTestNames[arrIndex][testName] !== undefined && crossTestSampleRowTestNames[arrIndex][testName] > 0)
			crossTestSampleRowTestNames[arrIndex][testName]++;
		else
			crossTestSampleRowTestNames[arrIndex][testName] = increment;
	} else {
		crossTestSampleRowTestNames[arrIndex] = {};
		crossTestSampleRowTestNames[arrIndex][testName] = increment;
	}
}

function setRejectionModalSave() {
	makeDirty();
	$jq("#reject-save").attr("disabled", true);
	if(($jq("#reject-select").val() && $jq("#reject-select").val().length) || $jq("#reject-other-reason").val().length) {
		$jq("#reject-save").attr("disabled", false);
	}
}

function resequenceSampleRows() {
	var table = $("samplesAddedTable");
	var rowsToKeep = sampleIdStart > 0 ? 0 : 1;

	for (var i = 1 + +rowsToKeep; i <= table.rows.length - 1; i++) {
		var rowId = parseInt($jq("#samplesAddedTable tr:nth-child(" + (i + 1) + ")").attr("id").substring(1));
		$jq("#sequence_" + rowId).text(i + +sampleIdStart);
	}
	setSave();
}
// special case for handling crossTest added rows
function removeFirstSampleRow(id) {
	var table = $("samplesAddedTable");

	table.deleteRow(1);

	for (var i = 1; i <= table.rows.length - 1; i++) {
		var rowId = parseInt($jq("#samplesAddedTable tr:nth-child(" + (i + 1) + ")").attr("id").substring(1));
		$jq("#sequence_" + rowId).text(i);
		if (i == 1)
			$jq("#remove_" + rowId).removeClass("icon-remove");
	}

	if (table.rows.length < 3) {
		$jq("#removeSamplesButton").attr("disabled", true).hide();
	}

	clearCrossTestSampleRowMap(id);
}

function removeSampleRow(id) {
	var table = $("samplesAddedTable");
	var rowsToKeep = sampleIdStart > 0 ? 0 : 1;

	for (var i = table.rows.length - 1; i > rowsToKeep; i--) {
		if ($jq("#samplesAddedTable tr:nth-child(" + (i + 1) + ")").attr("id") == "_" + id) {
			table.deleteRow(i);
	    	break;
		}
	}

	resequenceSampleRows();
	if (table.rows.length < 2 + +rowsToKeep) {
		$jq("#removeSamplesButton").attr("disabled", true).hide();
		if (sampleIdStart > 0) $jq("#samplesAddedTable").hide();
	}

	clearCrossTestSampleRowMap(id);
}

function clearCrossTestSampleRowMap(id) {
	for (var i = 0; i < crossTestSampleRowMap.length; i++) {
		if (crossTestSampleRowMap[i] !== undefined && crossTestSampleRowMap[i] == id) {
			$jq("#crossPanelsTestsTable tr:nth-child(" + (i + 1) + ") input[type='radio']").each(function(){ $jq(this).prop("checked", false); });
			$jq("#crossPanelsTestsTable tr:nth-child(" + (i + 1) + ") input.required").each(function(){ $jq(this).val("unselected"); });
			crossTestSampleRowMap[i] = '';
		}
	}
	crossTestSampleRowPanelIds[id] = {};
	crossTestSampleRowTestIds[id] = {};
	crossTestSampleRowTestNames[id] = {};
}

function confirmRemoveAll() {
	$jq("#confirm-modal .btn-danger").unbind("click").click(function() {
		resetSampleRows();
	});
	$jq("#confirm-modal").modal('show');
}

function resetSampleRows() {
	var table = $("samplesAddedTable");
	for (var i = table.rows.length - 1; i > 0; i--) {
		clearCrossTestSampleRowMap($jq("#samplesAddedTable tr:nth-child(" + (i + 1) + ")").attr("id").substring(1));
		table.deleteRow(i);
	}
	if (sampleIdStart == 0)
		addEmptySampleRow();
	crossTestSampleRowMap = [];
	crossTestSampleRowPanelIds = [];
	crossTestSampleRowTestIds = [];
	crossTestSampleRowTestNames = [];
	$jq("#removeSamplesButton").attr("disabled", true).hide();
	setSave();
}

function addEmptySampleRow(flag) {
	var rowsToKeep = sampleIdStart > 0 ? 0 : 1;

	if (typeof flag == 'undefined' || flag != "notDirty")
		makeDirty();
	
	// fade table in if hidden
	if ($jq("#samplesAddedTable").is(":hidden")) {
		$jq("#samplesAddedTable").fadeIn();
	}

	var rowId = 1 + +sampleIdStart;
	if ($jq("#samplesAddedTable tr:last").attr("id") != null) {
		rowId = parseInt($jq("#samplesAddedTable tr:last").attr("id").substring(1)) + 1;
	}
	
	// duplicate sample entry row template, update all ids
	$jq("#_tmpl").clone().find("a, button, div, i, input, label, select, span, td").each(function() {
		if ($jq(this).attr("id") != null) {
			$jq(this).val('').attr('id', function(_, id) { return id.substring(0, id.indexOf('_')) + '_' + rowId; });
			if ($jq(this).attr("id").substring(0, $jq(this).attr("id").indexOf('_')) == "initialConditionOtherReason") {
				$jq(this).attr('placeholder', '<%= StringUtil.getMessageForKey("sample.entry.initial.condition.other.placeholder")%>');
				$jq(this).focus(function() {
					var input = $jq(this);
					if (input.val() == input.attr('placeholder')) {
						input.val('');
						input.removeClass('-ms-input-placeholder');
					}
				}).blur(function() {
					var input = $jq(this);
					if (input.val() == '' || input.val() == input.attr('placeholder')) {
						input.addClass('-ms-input-placeholder');
						input.val(input.attr('placeholder'));
					}
				}).blur().hide();
			}
			if ($jq(this).attr("id").substring(0, $jq(this).attr("id").indexOf('_')) == "sequence") $jq(this).html(rowId);
		}
		if ($jq(this).attr("for") != null) {
			if ($jq(this).attr("for").indexOf('_') != -1) $jq(this).attr("for", function(_, id) { return id.substring(0, id.indexOf('_')) + '_' + rowId; });
		}
		// add "remove row" functionality for all but first row, unless on sample edit page where all added rows are removable
		if (rowId > rowsToKeep) {
			if ($jq(this).attr("id") != null && $jq(this).attr("id").substring(0, $jq(this).attr("id").indexOf('_')) == "remove") {
				$jq(this).addClass("icon-remove").click(function() {
					removeSampleRow(rowId);
				});
			}
		}
	}).end().attr("id", function(_, id) { return id.substring(0, id.indexOf('_')) + '_' + rowId; }).appendTo("#samplesAddedTable").fadeIn();
	
	// create autocomplete elements, if so configured
	if (useSampleTypeAutocomplete) {
		new AjaxJspTag.Autocomplete(
			"ajaxAutocompleteXML", {
			source: "typeOfSampleDesc_" + rowId,
			target: "typeOfSampleId_" + rowId,
			minimumCharacters: "1",
			className: "autocomplete",
			parameters: "typeOfSampleDesc={typeOfSampleDesc_" + rowId + "},domain=H,provider=SampleTypeAutocompleteProvider,fieldName=description,idName=id"
		});
	}
	
	if (useSampleSource && useSampleSourceAutocomplete) {
		new AjaxJspTag.Autocomplete(
			"ajaxAutocompleteXML", {
			source: "sourceOfSampleDesc_" + rowId,
			target: "sourceOfSampleId_" + rowId,
			minimumCharacters: "1",
			className: "autocomplete",
			parameters: "sourceOfSampleDesc={sourceOfSampleDesc_" + rowId + "},domain=H,provider=SampleSourceAutocompleteProvider,fieldName=description,idName=id"
		});
	}
	
	// add multiselect function for new sample condition list. Passes value(s) to identical list in rejection modal
 	$jq('#condition-select_' + rowId).selectList({
     	classPrefix:'mslist',
 		template: '<li id="%value%"><i class="test-remove icon-remove"></i> %text%</li>',
 		onAdd: function (select, value, text) {
			// changes the dropdown to show new text
  			$jq('#sample-condition_' + rowId).find('.mslist-select').children(":first").text('<%= StringUtil.getMessageForKey("sample.entry.initial.condition.select.more") %>');
  			addRemoveOtherConditionInput(rowId);
  		},
  		onRemove: function (select, value, text) {
			// changes the dropdown to show new text
  			var count = $jq("#sample-condition_" + rowId + " .mslist-list li").length;
  			if (count == 0) {
  				$jq('#sample-condition_' + rowId).find('.mslist-select').children(":first").text('<%= StringUtil.getMessageForKey("sample.entry.initial.condition.select.title") %>');
  			}
  			addRemoveOtherConditionInput(rowId);
  		}
  	});

	// add functions for sample rejection functionality
	$jq('#reject_' + rowId).change(function () {
		if ($jq(this).attr("checked")) {
			populateRejectionForSampleItem(rowId);
		} else {
			$jq("#confirm-modal .confirm-close").unbind("click").click(function() {
				$jq("#reject_" + rowId).prop("checked", true);
			});
			$jq("#confirm-modal .btn-danger").unbind("click").click(function() {
				resetRejectionFields(rowId);
				setSave();
			});
			$jq("#confirm-modal-body-text").text('<%= StringUtil.getMessageForKey("warning.cancel.reject")%>');
			$jq("#confirm-modal").modal('show');
		}
	});
	$jq('#edit-reject_' + rowId).click(function() {
		populateRejectionForSampleItem(rowId);
	});

	//set collection date/time
	if (useCollectionDate && autoFillCollectionDate) {
		$jq("#collectionDate_" + rowId).val("<%=entryDate%>");
		$jq("#collectionTime_" + rowId).val(getCurrentTime());
	}

	// show remove all button, if more than 'rowsToKeep' rows exists
	if (rowId > rowsToKeep) {
		$jq("#removeSamplesButton").attr("disabled", false).show();
	}
	
	resequenceSampleRows();
}

function sampleTypeChanged(element) {
	var row = element.id.substring(element.id.indexOf("_") + 1);
	$jq("#testIds_" + row).val("");
	$jq("#panelIds_" + row).val("");
	$jq("#tests_" + row).empty().hide();
	toggleAssignAndRejectDisabled(row, $jq("#typeOfSampleDesc_" + row).val() == "" ? true : false);
}

function toggleAssignDisabled(row, disable) {
	if (disable) {
		$jq("#assign_" + row).attr("disabled", disable);	
	} else {
		if (!$jq("#typeOfSampleDesc_" + row).hasClass("error")) $jq("#assign_" + row).attr("disabled", disable);
	}
}

function toggleAssignAndRejectDisabled(row, disable) {
	toggleAssignDisabled(row, disable);
	$jq("#reject_" + row).attr("disabled", disable);
}

function resetRejectionFields(row) {
	resetRejectionModalFields();
	$jq("#rejectionIds_" + row).val("");
	$jq("#rejectionOther_" + row).val("");
	$jq("#rejectionTech_" + row).val("");
	$jq("#rejectionNotes_" + row).val("");
	$jq("#reject_" + row).prop("checked", false);
	if (!$jq("#typeOfSampleDesc_" + row).hasClass("error")) $jq("#assign_" + row).attr("disabled", false);
	$jq("#reject-saved_" + row).val("false");
	$jq("#reject_" + row).closest('tr').removeClass('rejected-sample');
	$jq("#sample-condition_" + row + " ul.mslist-list").removeClass('rejected-sample');
	$jq("#edit-reject_" + row).hide();
}

function resetRejectionModalFields() {
	$jq("#modalSampleReject :input").val("");
	$jq("#reject-select").empty();
	$jq("#reject-forms select.mslist-select option").attr("disabled", false);
	$jq("#reject-forms").find('.mslist-select').children(":first").text('<%= StringUtil.getMessageForKey("sample.entry.rejection.reason.select.title")%>');
	$jq("#reject-forms ul.mslist-list").empty();
	$jq("#reject-save").attr("disabled", true);
}

function cancelRejection() {
	var row = $jq("#modalSampleReject").data("rowId");
	if ($jq("#modalSampleReject").data("modalUpdated")) {
		$jq("#confirm-modal .confirm-close").unbind("click").click(function() {
			cancelConfirm($jq("#modalSampleReject"));
		});
		$jq("#confirm-modal .btn-danger").unbind("click").click(function() {
			if ($jq("#reject-saved_" + row).val() != "true") {
				resetRejectionFields(row);
			}
		});
		$jq("#modalSampleReject").modal('hide');
		$jq("#confirm-modal").modal('show');
	} else {
		if ($jq("#reject-saved_" + row).val() != "true") {
			resetRejectionFields(row);
		}
	}
}

function cancelAssign() {
	if ($jq("#modalTestAssign").data("modalUpdated")) {
		$jq("#confirm-modal .confirm-close").unbind("click").click(function() {
			cancelConfirm($jq("#modalTestAssign"));
		});
		$jq("#modalTestAssign").modal('hide');
		$jq("#confirm-modal").modal('show');
	}
	setSave();
}

function cancelConfirm(openModal) {
	$jq('#confirm-modal').modal('hide');
	openModal.modal('show');
	openModal.data("modalUpdated", true);	
}

function unloadPanelsAndTests() {
	$jq("#panelList").empty();
	$jq("#panelsSelected ul.display-panels").empty();
	$jq("#testList").empty();
	$jq("#testsSelected ul.display-tests").empty();
}

function loadPanelsAndTestsForSampleType(id) {
	selectedRowId = id;

	if ($jq("#" + sampleTypeField + "_" + id).val().length > 0) {
		if (currentCheckedType != $jq("#" + sampleTypeField + "_" + id).val()) {
			unloadPanelsAndTests();
			// this is an asynchronous call and populatePanelsAndTestsForSampleItem will be called on the return of the call
    		getTestsForSampleType($jq("#" + sampleTypeField + "_" + id).val(), processGetTestSuccess, processGetTestFailure);
    	} else {
    		populatePanelsAndTestsForSampleItem();
    	}
	}
}

function insertPanelIntoList(i, panel) {
	var panelList = $jq("#panelList");
	var name = getValueFromXmlElement(panel, "name");
	var id = getValueFromXmlElement(panel, "id");
	var tests = getValueFromXmlElement(panel, "testMap").split(",");

	panelList.append(getPanelHtmlFragment(i, name, id));

	for (var j = 0; j < tests.length; j++) {
		$jq("#test_" + tests[j]).addClass("panel_" + i);
	}
}

function insertTestIntoList(i, test) {
	var testList = $jq("#testList");
	var name = getValueFromXmlElement(test, "name");
	var id = getValueFromXmlElement(test, "id");

	testList.append(getTestHtmlFragment(i, name, id));
}

function getValueFromXmlElement(parent, tag){
	var element = parent.getElementsByTagName(tag);

	return (element && element.length > 0)  ? element[0].childNodes[0].nodeValue : "";
}

function togglePanelOrTest(type, id, checked) {
	$jq("#" + id).prop("checked", checked);

	if (type == "panel") {
		$jq("#testList input." + id).each(function() {
			togglePanelOrTest('test', this.id, checked);
		});
	}

	if (checked) {
		$jq("#" + type + "sSelected ul.empty-list").hide();
		if ($jq(".selected-" + id).length == 0) {
			$jq(".display-" + type + "s").append("<li class='nobullet selected-" + id + "'><i class='test-remove icon-remove' id='delete-" + id +"'></i> " +
												 $jq("#" + id)[0].nextSibling.nodeValue + "</li>");
			if (type == "panel") {
				$jq("#delete-" + id).hover(function () {
					// Highlights which tests will be deleted on hover
					$jq("#testList input." + id).each(function() {
						$jq(".selected-" + this.id).toggleClass('hover-show-tests');
					});	
				});
			}

			$jq("#delete-" + id).click(function () {
				togglePanelOrTest(type, id, false);
			});
		}
	} else {
		$jq(".selected-" + id).remove();
		if ($jq(".display-" + type + "s").children().length == 0) {
			$jq("#" + type + "sSelected ul.empty-list").show();
		}
	}
	
	if ($jq("#modalTestAssign").is(":visible")) $jq("#modalTestAssign").data("modalUpdated", true);
}

function populatePanelsAndTestsForSampleItem() {
	currentCheckedType = $jq("#" + sampleTypeField + "_" + selectedRowId).val();

	$jq("#panelList input").each(function() {
		togglePanelOrTest('panel', this.id, false);
	});
	
	if ($jq("#panelIds_" + selectedRowId).val().length > 0) {
		var panelIds = $jq("#panelIds_" + selectedRowId).val().split(',');
		for (var i = 0; i < panelIds.length; i++) {
			togglePanelOrTest('panel', $jq("#panelList input[value='" + panelIds[i] + "']").attr("id"), true);
		}
	}

	$jq("#testList input").each(function() {
		togglePanelOrTest('test', this.id, false);
	});
	
	if ($jq("#testIds_" + selectedRowId).val().length > 0) {
		var testIds = $jq("#testIds_" + selectedRowId).val().split(',');
		for (var i = 0; i < testIds.length; i++) {
			togglePanelOrTest('test', $jq("#testList input[value='" + testIds[i] + "']").attr("id"), true);
		}
	}

	$jq("#modalTestAssign").modal("show");
}

function savePanelsAndTestsForSampleItem() {
	$jq("#testIds_" + selectedRowId).val("");
	$jq("#panelIds_" + selectedRowId).val("");
	$jq("#tests_" + selectedRowId).html("");
	
	$jq("#panelList input").each(function() {
		if (this.checked) {
			$jq("#panelIds_" + selectedRowId)[0].value += this.value + ',';
		}
	});
	if ($jq("#panelIds_" + selectedRowId).val().length > 0) {
		$jq("#panelIds_" + selectedRowId).val($jq("#panelIds_" + selectedRowId).val().slice(0, -1)); 
	}

	$jq("#testList input").each(function() {
		if (this.checked) {
			$jq("#testIds_" + selectedRowId)[0].value += this.value + ',';
			$jq("#tests_" + selectedRowId).append($jq("#" + this.id)[0].nextSibling.nodeValue.slice(0, -1) + ',');
		}
	});
	if ($jq("#testIds_" + selectedRowId).val().length > 0) {
		$jq("#testIds_" + selectedRowId).val($jq("#testIds_" + selectedRowId).val().slice(0, -1)); 
	}
	if ($jq("#tests_" + selectedRowId).html().length > 0) {
		$jq("#tests_" + selectedRowId).html($jq("#tests_" + selectedRowId).html().slice(0, -1)).show(); 
	} else {
		$jq("#tests_" + selectedRowId).hide();
	}
	setSave();

	// open patient info modal, if flag is set
	if (usePatientInfoModal) {
		$jq('#modalTestAssign').modal('hide');
		populatePatientInfoModal();
	}
}

function getPanelHtmlFragment(id, name, value) {
	return "\
	<label class=\"checkbox\">\
		<input type=\"checkbox\"\
			   name=\"panels[]\"\
			   value=\"" + value + "\"\
			   id=\"panel_" + id + "\"\
			   onchange=\"togglePanelOrTest('panel', this.id, this.checked)\">" + name + "\
	</label>";
}

function getTestHtmlFragment(id, name, value) {
	return "\
	<label class=\"checkbox\">\
		<input type=\"checkbox\"\
			   name=\"tests[]\"\
			   value=\"" + value + "\"\
			   id=\"test_" + id + "\"\
			   class=\"\"\
			   onchange=\"togglePanelOrTest('test', this.id, this.checked)\">" + name + "\
	</label>";
}

function processGetTestFailure(xhr) {
  	//ajax call failed
	$jq("#loading-modal").modal('hide');
}

function processGetTestSuccess(xhr){
	//alert(xhr.responseText);
	var response = xhr.responseXML.getElementsByTagName("formfield").item(0);

	var tests = response.getElementsByTagName("test");
	for (var i = 0; i < tests.length; i++){
		insertTestIntoList(i, tests[i]);
	}

	var panels = response.getElementsByTagName("panel");
	for (var i = 0; i < panels.length; i++){
		insertPanelIntoList(i, panels[i]);
	}

	populatePanelsAndTestsForSampleItem();
}

function populateRejectionForSampleItem(id) {
	resetRejectionModalFields();
	
	$jq("#modalSampleReject").data("rowId", id);

	var rejections = [];
	var otherReason = "";
	// if sample rejection data hasn't already been saved, populate using initial conditions data
	if ($jq("#reject-saved_" + id).val() != "true") {
		$jq("#sample-condition_" + id + " .mslist-list li").each(function() {
			var initCondText = $jq.trim($jq(this).text());
			if (initCondText.indexOf('<%= StringUtil.getMessageForKey("qa.event.initial.condition.other") %>') < 0) {
				// values in the rejection list are different from those in the initial condition list, so need to compare using text
				$jq("#reject-forms select.mslist-select option").each(function() {
					if ($jq.trim($jq(this).text()) == initCondText) {
 						rejections.push($jq(this).val());
					}
				});
			}
		});
		if ($jq("#initialConditionOtherReason_" + id).val() != $jq("#initialConditionOtherReason_" + id).attr('placeholder'))
	        otherReason = $jq("#initialConditionOtherReason_" + id).val();
	} else {
		if ($jq("#rejectionIds_" + id).val().length > 0) {
			rejections = $jq("#rejectionIds_" + id).val().slice(0, -1).split(",");
		}
		otherReason = $jq("#rejectionOther_" + id).val();
	}
	if (rejections.length > 0) $jq("#reject-select").val(rejections);
	$jq("#reject-other-reason").val(otherReason);
	$jq("#reject-tech-name").val($jq("#rejectionTech_" + id).val());
//	$jq("#reject-notes").val($jq("#rejectionNotes_" + id).val());
	setRejectionModalSave();

	$jq("#modalSampleReject").modal("show");
}

function saveRejectionForSampleItem(id) {
	$jq("#rejectionIds_" + id).val("");
	$jq("#reject-forms .mslist-list li").each(function() {
		$jq("#rejectionIds_" + id)[0].value += this.id + ',';
	});
	$jq("#rejectionOther_" + id).val($jq("#reject-other-reason").val());
	$jq("#rejectionTech_" + id).val($jq("#reject-tech-name").val());
//	$jq("#rejectionNotes_" + id).val($jq("#reject-notes").val());
}

function loadXml() {
	saveSamples();
	if (usePatientInfoModal)
		savePatients();
}

function saveSamples(){
	var xml = convertSamplesToXml();
	$("sampleXML").value = xml;
}

function convertSamplesToXml(){
	var rows = $("samplesAddedTable").rows;

	var xml = "<?xml version='1.0' encoding='utf-8'?><samples>";

	for( var i = 1; i < rows.length; i++ ){
		xml = xml + convertSampleToXml( rows[i].id );
	}

	xml = xml + "</samples>";

	return xml;
}

function convertSampleToXml( id ){
	var initialConditionOther = "";
	var rejectOther = "";
	var rejectTech = "";
	var rejectNotes = "";
	
	var xml = "<sample sampleID='" + $jq("#" + sampleTypeField + id).val() +
			  "' sourceID='" + (useSampleSource ? $jq("#" + sampleSourceField + id).val() : '') +
			  "' date='" + (useCollectionDate ? $jq("#collectionDate" + id).val() : '') +
			  "' time='" + (useCollectionDate ? $jq("#collectionTime" + id).val() : '') +
			  "' collector='" + (useCollector ? $jq("#collector" + id).val() : '') +
			  "' tests='" + $jq("#testIds" + id).val() +
              "' testSectionMap='" +
              "' testSampleTypeMap='" +
			  "' panels='" + $jq("#panelIds" + id).val() + "'";

	if( useInitialSampleCondition ){
		var initialConditions = $("condition-select" + id);
		var optionLength = initialConditions.options.length;
		var addedOptions = false;
		initialConditionOther = $jq.trim($jq("#initialConditionOtherReason" + id).val());
		xml += " initialConditionIds='";
		for( var i = 0; i < optionLength; ++i ){
			if( initialConditions.options[i].selected && $jq.isNumeric(initialConditions.options[i].value) ) {
				xml += initialConditions.options[i].value + ",";
				addedOptions = true;
			}
		}

		if( addedOptions ) xml = xml.substring(0, xml.length - 1);
		xml += "'";
	}

	if (useSampleRejection) {
		var rejectIDs = $jq("#rejectionIds" + id).val().slice(0, -1);
		rejectOther = $jq.trim($jq("#rejectionOther" + id).val());
		rejectTech = $jq.trim($jq("#rejectionTech" + id).val());
		rejectNotes = $jq.trim($jq("#rejectionNotes" + id).val());
	
		xml += " rejectionIds='" + rejectIDs + "'";
	}
	
	xml += ">";
	
	if (useInitialSampleCondition && initialConditionOther.length > 0 &&
		initialConditionOther != $jq.trim($jq("#initialConditionOtherReason" + id).attr('placeholder')))
		xml += "<initialConditionOther>" + initialConditionOther.escapeHTML() + "</initialConditionOther>";
	if (useSampleRejection && rejectOther.length > 0)
		xml += "<rejectionOther>" + rejectOther.escapeHTML() + "</rejectionOther>";
	if (useSampleRejection && rejectTech.length > 0)
		xml += "<rejectionTech>" + rejectTech.escapeHTML() + "</rejectionTech>";
	if (useSampleRejection && rejectNotes.length > 0)
		xml += "<rejectionNotes>" + rejectNotes.escapeHTML() + "</rejectionNotes>";

	xml +=  "</sample>";

	return xml;
}

function processSuccess(xhr) {
  	var message = xhr.responseXML.getElementsByTagName("message")[0];
  	var formfield = xhr.responseXML.getElementsByTagName("formfield")[0];
	var labElement = formfield.firstChild.nodeValue;
	var success = false;

	if (message.firstChild.nodeValue.substring(0, 5) == "valid"){
		success = true;
	}
	selectFieldErrorDisplay( success, $(labElement));
	setSampleFieldValidity( success, labElement);
  	if (labElement.substring(0, 16) == "typeOfSampleDesc")
  		toggleAssignAndRejectDisabled(labElement.substring(labElement.indexOf("_") + 1), !success);
  	setSave();
}

function validateSampleType(field) {
	 if ($F(field) == '' || $F(field) == null) {
		selectFieldErrorDisplay(false, field);
		setSampleFieldValidity(false, field.id);
		setSave();
	 } else {
    	new Ajax.Request (
                     'ajaxXML',  //url
                      {//options
                        method: 'get', //http method
                        parameters: 'provider=QuickEntrySampleTypeValidationProvider&field=' + field.id + '&id=' + encodeURIComponent($F(field)),      //request parameters
                        //indicator: 'throbbing'
                        onSuccess:  processSuccess,
                        onFailure:  processGetTestFailure
                      }
                     );
	 }
}

function validateSampleSource(field) {
/*AIS - bugzilla 1396
 Added if constraint-- to check if it is invalid, only when it is filled in
*/
	if ($F(field) == '' || $F(field) == null) {
		selectFieldErrorDisplay(true, field);
		setSampleFieldValidity(true, field.id);
		setSave();
 	} else {
   		new Ajax.Request (
                     'ajaxXML',  //url
                      {//options
                        method: 'get', //http method
                        parameters: 'provider=QuickEntrySampleSourceValidationProvider&field=' + field.id + '&id=' + encodeURIComponent($F(field)),      //request parameters
                        //indicator: 'throbbing'
                        onSuccess:  processSuccess,
                        onFailure:  processGetTestFailure
                      }
                     );
	}
}


function /*void*/ addSampleChangedListener( listener ){
	sampleChangeListeners.push( listener );
}

function /*void*/ notifyChangeListeners(){
	for(var i = 0; i < sampleChangeListeners.length; i++){
			sampleChangeListeners[i]();
	}
}

function setupPrintLabelsModal(field1, field2) {
	$('accessionRangeStart').value = '';
	$('accessionRangeEnd').value = '';
	$('labelAccessionNumber').value = '';
	$('labelAccessionNumber2').value = '';
	$('accessionCount').value = '';
	$('masterLabels').value = '1';
	enableAccessionGeneratorFields(true);
	enableAccessionRangeFields(true);

	if (field1 && isFieldValid(field1.id) && $(field1).value.length > 0) {
		$('accessionRangeStart').value = $(field1).value;
		$('labelAccessionNumber').value = $(field1).value;
		$('accessionCount').disabled = true;
	}
	if (field2 && isFieldValid(field2.id) && $(field2).value.length > 0) {
		$('accessionRangeEnd').value = $(field2).value;
		$('labelAccessionNumber2').value = $(field2).value;
		$('accessionCount').disabled = true;
	}
	<% if (useSpecimenLabels) { %>
	$('itemLabels').value = $("samplesAddedTable").rows.length - 1;
	<% } %>
	setSave();
}

function submitPrintJob() {
	new Ajax.Request (
	   	'ajaxReportsXML',  //url
	   	{//options
	    	method: 'get', //http method
	       	parameters: 'provider=SampleLabelPrintProvider&labelAccessionNumber=' + $F('labelAccessionNumber') +
						'&labelAccessionNumber2=' + $F('labelAccessionNumber2') +
   						'&accessionCount=' + $F('accessionCount') +
	       				'&printerName=' + escape($F('printerName')) + 
	       				'&masterLabels=' + $F('masterLabels') + 
	       				'&itemLabels=' + ($('itemLabels') ? $F('itemLabels') : ''),      //request parameters
	       	//indicator: 'throbbing'
	       	onSuccess:  processPrintSuccess,
	       	//onFailure:  processFailure
	   	}
	);
}

function processPrintSuccess(xhr) {
  	var message = xhr.responseXML.getElementsByTagName("message")[0];
  	//alert("I am in parseMessage and this is message, formfield " + message + " " + formfield);
	var msg = message.firstChild.nodeValue;
	var alertMsg = '';
	if (msg.substring(0, 7) == "success") {
		alertMsg = "<bean:message key="print.success"/>";
		zplData = msg;
		showZplModal();
		if ($jq("#labelSimulation").hasClass("hide")) $jq("#labelSimulation").removeClass("hide");
	} else {
		if (!$jq("#labelSimulation").hasClass("hide")) $jq("#labelSimulation").addClass("hide");
		switch (msg) {
			case "failMaxLabels":
				alertMsg = "<bean:message key="errors.labelprint.exceeded.maxnumber" arg0="<%=maxLabels%>"/>";
				break;
			case "failPrinter":
				alertMsg = "<bean:message key="errors.labelprint.no.printer"/>";
				break;
			case "fail":
				alertMsg = "<bean:message key="errors.labelprint.general.error"/>";
				break;
		}
	}
	$jq("#successMsg").text(alertMsg);
	showSuccessMessage(true);
}

function cancelPrint() {
	if ($jq("#label-modal").data("modalUpdated")) {
		$jq("#confirm-modal .confirm-close").unbind("click").click(function() {
			cancelConfirm($jq("#label-modal"));
		});
		$jq("#label-modal").modal('hide');
		$jq("#confirm-modal").modal('show');
	}
	setSave();
}

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
function addRemoveOtherConditionInput(id) {
	if ($jq("#sample-condition_" + id + " li:contains('<%= StringUtil.getMessageForKey("qa.event.initial.condition.other") %>')").length > 0) {
    	$jq("#initialConditionOtherReason_" + id).show();
    } else {
        $jq("#initialConditionOtherReason_" + id).hide().val("");
    }
}
            
$jq(document).ready(function () {

	// Modal definitions
	$jq('#modalTestAssign, #modalSampleReject, #label-modal, #confirm-modal, #warning-modal, #loading-modal, #zpl-modal').modal({
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

	// add multiselect function for rejection list. Gets value(s) passed from sample condition, but can work independently
	$jq("#reject-select").selectList({
		classPrefix:'mslist',
		instance: true,
		template: '<li id="%value%"><i class="test-remove icon-remove"></i> %text%</li>',
		onAdd: function (select, value, text) {
			// for some reason, this function is called when the modal is shown (or hidden?), so work around that accordingly
			var rowId = $jq("#modalSampleReject").data("rowId");
			var activeLen = $jq("#reject-forms .mslist-list li").length;
			var savedLen = $jq("#rejectionIds_" + rowId).val().length > 0 ? $jq("#rejectionIds_" + rowId).val().slice(0, -1).split(",").length : 0;
 	 		var initCondLen = $jq("#condition-select_" + rowId + " option:selected").length;
 	 		if (($jq("#reject-saved_" + rowId).val() == "true" && activeLen != savedLen) ||
 	 			($jq("#reject-saved_" + rowId).val() != "true" && activeLen != initCondLen)) {
				$jq("#modalSampleReject").data("modalUpdated", true);
 	 		}
	 		if (activeLen > 0) {
				// changes the dropdown to show new text
				$jq("#reject-forms").find('.mslist-select').children(":first").text('<%= StringUtil.getMessageForKey("sample.entry.rejection.reason.select.more") %>');
	 		}
			setRejectionModalSave();
		},
		onRemove: function (select, value, text) {
			// changes the dropdown to show new text
			if ($jq("#reject-forms .mslist-list li").length == 0) {
				$jq("#reject-forms").find('.mslist-select').children(":first").text('<%= StringUtil.getMessageForKey("sample.entry.rejection.reason.select.title")%>');
			}
			setRejectionModalSave();
			$jq("#modalSampleReject").data("modalUpdated", true);
		}
	});
	$jq("#reject-save").click(function() {
		var rowId = $jq("#modalSampleReject").data("rowId");
		saveRejectionForSampleItem(rowId);
		$jq("#reject_" + rowId).closest('tr').addClass('rejected-sample');
		$jq("#sample-condition_" + rowId + " ul.mslist-list").addClass('rejected-sample');
		toggleAssignDisabled(rowId, true);
		$jq("#reject-saved_" + rowId).val("true");
		$jq("#edit-reject_" + rowId).show();
		makeDirty();
		setSave();
	});
	$jq("#cancel-reject").click(function() {
		cancelRejection();
	});
		
	// This to force placeholder functionality in browsers that don't support it like IE 8 and 9
	$jq('[placeholder]').focus(function() {
		var input = $jq(this);
		if (input.val() == input.attr('placeholder')) {
			input.val('');
			input.removeClass('-ms-input-placeholder');
		}
	}).blur(function() {
		var input = $jq(this);
		if (input.val() == '' || input.val() == input.attr('placeholder')) {
			input.addClass('-ms-input-placeholder');
			input.val(input.attr('placeholder'));
		}
	}).blur();

	// Remove columns if so configured
	if (!useSampleRejection)
		$jq(".sampleRejectionCol").remove();
});
</script>

<table style="display: none">
	<!-- Begin empty sample row template -->
	<tr id="_tmpl">
		<td style="width: 14px;">
			<span id="remove_tmpl"></span>
		</td>
		<td>
			<span id="sequence_tmpl">1</span>
		</td>
		<td>
		<% if (useSampleTypeAutocomplete) { %>
			<app:text name="<%=formName%>" 
					  property="typeOfSampleDesc" 
	  				  onblur="if(this.value.toUpperCase() != lastTypeClicked.toUpperCase())sampleTypeChanged(this);this.value=this.value.toUpperCase();validateSampleType(this);"
	  				  onfocus="lastTypeClicked = this.value;"
	  				  onchange="makeDirty();"
	  				  styleClass="text input-medium" 
					  styleId="typeOfSampleDesc_tmpl"/>
			<html:hidden property="typeOfSampleId" name="<%=formName%>" styleId="typeOfSampleId_tmpl"/>
       	<% } else { %>
			<html:select name="<%=formName%>"
						 property="typeOfSampleDesc"
						 onchange="sampleTypeChanged(this);makeDirty();setSave();"
						 styleId="typeOfSampleDesc_tmpl"
						 value="0">
				<app:optionsCollection name="<%=formName%>" property="sampleTypes" label="value" value="id" />
			</html:select>
      	<% } %>
		</td>
		<% if (useSampleSource) { %>
		<td>
			<% if (useSampleSourceAutocomplete) { %>
			<app:text name="<%=formName%>" 
					  property="sourceOfSampleDesc" 
					  onblur="this.value=this.value.toUpperCase();validateSampleSource(this);" 
	  				  onchange="makeDirty();"
					  styleClass="text input-medium" 
	  				  styleId="sourceOfSampleDesc_tmpl"/>
			<div id="sourceOfSampleDescMessage_tmpl" class="blank">&nbsp;</div>
			<html:hidden property="sourceOfSampleId" name="<%=formName%>" styleId="sourceOfSampleId_tmpl"/>
    		<% } else { %>
			<html:select name="<%=formName%>"
						 property="sourceOfSampleDesc"
						 onchange="makeDirty();"
						 styleId="sourceOfSampleDesc_tmpl"
						 value="0">
				<app:optionsCollection name="<%=formName%>" property="sampleSources" label="value" value="id" />
			</html:select>
			<% } %>
		</td>
		<% } %>
		<% if(useInitialSampleCondition){ %>
	    <td id="sample-condition_tmpl">
			<html:select name='<%=formName%>'
 						 property="initialSampleConditionList"
 						 multiple="true"
 						 title='<%= StringUtil.getMessageForKey("sample.entry.initial.condition.select.title")%>'
 						 styleId = 'condition-select_tmpl'
 						 styleClass="multi-select condition-select"
 						 onchange="makeDirty()">
 				<option disabled><%= StringUtil.getMessageForKey("sample.entry.initial.condition.select.conditions")%></option>
 				<optgroup label='<%= StringUtil.getMessageForKey("dict.qa.event.category.form.error")%>'>
					<logic:iterate id="optionValue" name='<%=formName%>' property="initConditionFormErrorsList" type="IdValuePair" >
						<option value='<%=optionValue.getId()%>' >
							<bean:write name="optionValue" property="value"/>
						</option>
					</logic:iterate>
				</optgroup>
 				<optgroup label="<%= StringUtil.getMessageForKey("dict.qa.event.category.label.error")%>">
					<logic:iterate id="optionValue" name='<%=formName%>' property="initConditionLabelErrorsList" type="IdValuePair" >
						<option value='<%=optionValue.getId()%>' >
							<bean:write name="optionValue" property="value"/>
						</option>
					</logic:iterate>
				</optgroup>
 				<optgroup label="<%= StringUtil.getMessageForKey("dict.qa.event.category.misc")%>">
					<logic:iterate id="optionValue" name='<%=formName%>' property="initConditionMiscList" type="IdValuePair" >
						<option value='<%=optionValue.getId()%>' >
							<bean:write name="optionValue" property="value"/>
						</option>
					</logic:iterate>
				</optgroup>
 				<optgroup label="<%= StringUtil.getMessageForKey("sample.entry.initial.condition.other")%>">
 					<option><%= StringUtil.getMessageForKey("qa.event.initial.condition.other")%></option>
				</optgroup>
			</html:select>
			<html:text name="<%=formName%>" 
					   property="initialConditionOtherReason" 
					   onchange="makeDirty();" 
					   styleClass="input-medium"
					   style="margin-left: 10px"
	  				   styleId="initialConditionOtherReason_tmpl"
	  				   maxlength="80"/>
	  	</td>
		<% } %>
		<% if ( useCollectionDate ) { %>
		<td>
			<input type="text"
				   class="input-small"
				   id="collectionDate_tmpl"
				   name="collectionDate"
				   maxlength="10"
				   placeholder='<%= StringUtil.getMessageForKey("sample.date.placeholder") %>'
				   onchange="checkValidEntryDate(this);makeDirty()"/>
		</td>
		<td>
			<input type="text"
				   class="input-mini"
				   id="collectionTime_tmpl"
				   name="collectionTime"
				   maxlength="5"
				   placeholder='<%= StringUtil.getMessageForKey("sample.time.placeholder") %>'
				   onchange="checkValidEntryTime(this);makeDirty()"/>
		</td>
      	<% } %>
		<td>
			<input id="testIds_tmpl" type="hidden">
			<input id="panelIds_tmpl" type="hidden">
			<div id="tests_tmpl" class="display-tests-main test-container hide"></div>
			<button data-toggle="modal"
					onclick='loadPanelsAndTestsForSampleType(this.id.substring(this.id.indexOf("_") + 1))'
					id="assign_tmpl"
					disabled="disabled"><bean:message key="sample.entry.assignTests" /></button>
			<% if (useSpecimenLabels) { %>
			<button data-toggle="modal"
					id="printItemLabel_tmpl"
					class="pull-right"
					onclick="$jq('#label-modal').modal('show');"
					><bean:message key="label.button.printLabel" /></button>
			<% } %>
		</td>
		<td class="sampleRejectionCol">
			<input name="rejectionIds" id="rejectionIds_tmpl" type="hidden">
			<input name="rejectionOther" id="rejectionOther_tmpl" type="hidden">
			<input name="rejectionTech" id="rejectionTech_tmpl" type="hidden">
			<input name="rejectionNotes" id="rejectionNotes_tmpl" type="hidden">
			<input type="checkbox"
				   id="reject_tmpl"
				   disabled="disabled">
			<i class="icon-pencil edit-reject"
			   style="margin: 5px 0 0 5px; display: none"
			   id="edit-reject_tmpl"
			   title='<%= StringUtil.getMessageForKey("sample.entry.rejection.reason.edit") %>'>
			</i>
			<input type="hidden" id="reject-saved_tmpl" name="reject-saved" value="false">
		</td>
	</tr>
	<!-- End empty sample row template -->
</table>

<div id="crossPanels">
</div>

<!-- The table to hold added sample rows -->
<div class="row-fluid">
	<div id="samplesAdded" class="span12">	
		<table id="samplesAddedTable" class="table">
			<tr>
				<th style="width: 14px;"></th>
				<th><bean:message key="quick.entry.item"/></th>
				<th class="required-header"><bean:message key="sample.entry.sample.type"/></th>
				<% if (useSampleSource) { %>
				<th><bean:message key="sample.entry.sample.source"/></th>
            	<% } %>
				<% if (useInitialSampleCondition) { %>
               	<th><bean:message key="sample.entry.sample.condition"/></th>
            	<% } %>
				<% if ( useCollectionDate ) { %>
				<th><bean:message key="sample.collectionDate"/></th>
				<th><bean:message key="sample.collectionTime.noFormat"/></th>
            	<% } %>
				<th class="required-header"><bean:message key="sample.entry.sample.tests"/></th>
				<th class="sampleRejectionCol"><bean:message key="sample.entry.sample.reject"/></th>
			</tr>
		</table>
		<table class="table">
			<tr>
				<td>
					<button id="addSampleButton" onclick="addEmptySampleRow();return false;" disabled="disabled">
						<bean:message key="sample.entry.addSample" />
					</button>
					&nbsp;&nbsp;&nbsp;
					<button class="hide" id="removeSamplesButton" onclick="confirmRemoveAll();return false;" disabled="disabled">
						<bean:message key="sample.entry.removeAllSamples" />
					</button>
				</td>
			</tr>
		</table>
	</div>
    <div id="labelSimulation" class="hide">
    	<button onclick="showZplModal(); return false;">Show Label Simulation</button>
	</div>
</div>

<!-- Test assignment modal definition -->			
<div id="modalTestAssign" class="sample-modal modal hide fade">
	<div class="modal-header">
	   	<button type="button"
	   			class="close"
				onclick="cancelAssign();"
	   			data-dismiss="modal">&times;</button>
		<h3><bean:message key="sample.entry.choosePanelsTest" /></h3>
	</div>
	<div class="modal-body">
		<div class="row-fluid" id="tests-container">
			<div class="span6">
				<h3><bean:message key="sample.entry.panels" /></h3>
				<div class="checkbox-container-small" id="panelList">
				</div>
				<h3><bean:message key="sample.entry.sample.tests" /></h3>
				<div class="checkbox-container" id="testList">
				</div>
			</div>
			<div class="span6">
				<div id="panelsSelected">		
					<h3><bean:message key="quick.entry.assigned.panels" /></h3>
					<ul class="empty-list">
						<bean:message key="quick.entry.none.selected" />
					</ul>
					<ul class="display-panels">
					</ul>
				</div>
				<div id="testsSelected">		
					<h3><bean:message key="quick.entry.assigned.tests" /></h3>			
					<ul class="empty-list">
						<bean:message key="quick.entry.none.selected" />
					</ul>
					<ul class="display-tests">
					</ul>
				</div>
			</div>
		</div>
		<br />
	</div>
	<div class="modal-footer">
		<button class="btn btn-primary btn-large"
				data-dismiss="modal"
				onclick="savePanelsAndTestsForSampleItem();makeDirty()"><bean:message key="label.button.save" /></button> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
		<button class="btn btn-small"
				id="cancel-tests"
				data-dismiss="modal"
				onclick="cancelAssign();"><bean:message key="label.button.cancel" /></button>
	</div>
</div>

<!-- Sample rejection modal definition -->			
<div id="modalSampleReject" class="modal hide fade sample-modal">
	<div class="modal-header">
		<button type="button"
				onclick="cancelRejection();"
				class="close"
				data-dismiss="modal">&times;</button>
		<h3><bean:message key="quick.entry.reject.sample.item" /></h3>
	</div>
	<div class="modal-body">
		<div class="row-fluid" id="rejection-container">
			<div class="span12">
				<div class="control-group">
					<label class="control-label" for="reject-forms"><bean:message key="dict.qa.event.type.rejection" /></label>
					<div class="controls" id="reject-forms">
						<html:select name='<%=formName%>'
						 			 property="rejectionReasonList"
 						 			 multiple="true"
 						 			 title='<%= StringUtil.getMessageForKey("sample.entry.rejection.reason.select.title")%>'
 						 			 styleId = 'reject-select'
 						 			 styleClass="multi-select select-wide reject-reason-list">
 							<optgroup label="<%= StringUtil.getMessageForKey("dict.qa.event.category.form.error")%>">
								<logic:iterate id="optionValue" name='<%=formName%>' property="rejectionReasonFormErrorsList" type="IdValuePair" >
									<option value='<%=optionValue.getId()%>' >
										<bean:write name="optionValue" property="value"/>
									</option>
								</logic:iterate>
							</optgroup>
							<optgroup label="<%= StringUtil.getMessageForKey("dict.qa.event.category.label.error")%>">
								<logic:iterate id="optionValue" name='<%=formName%>' property="rejectionReasonLabelErrorsList" type="IdValuePair" >
									<option value='<%=optionValue.getId()%>' >
										<bean:write name="optionValue" property="value"/>
									</option>
								</logic:iterate>
							</optgroup>
							<optgroup label="<%= StringUtil.getMessageForKey("dict.qa.event.category.misc")%>">
								<logic:iterate id="optionValue" name='<%=formName%>' property="rejectionReasonMiscList" type="IdValuePair" >
									<option value='<%=optionValue.getId()%>' >
										<bean:write name="optionValue" property="value"/>
									</option>
								</logic:iterate>
							</optgroup>
						</html:select>
					</div>
				</div>
				<div class="control-group">
					<label class="control-label" for="reject-other-reason"><bean:message key="sample.entry.rejection.reason.other.placeholder"/></label>
					<div class="controls">
						<html:text name="<%=formName%>" 
					   			   property="rejectionReasonOtherReason" 
					   			   onchange="setRejectionModalSave();$jq('#modalSampleReject').data('modalUpdated', true);"
					   			   styleClass="input-xlarge"
					   			   styleId="reject-other-reason"
					   			   maxlength="1000"/>
					</div>
				</div>
				<div class="control-group">
					<label class="control-label" for="reject-tech-name"><bean:message key="sample.entry.rejection.tech.name"/></label>
					<div class="controls">
						<input type="text" class="input-xlarge" id="reject-tech-name" maxlength="30" onchange='$jq("#modalSampleReject").data("modalUpdated", true);'>
					</div>
				</div>
				<div class="control-group hide">
					<label class="control-label" for="reject-notes"><bean:message key="sample.entry.rejection.notes"/></label>
					<div class="controls">
						<input type="text" class="input-xlarge" id="reject-notes" maxlength="1000" onchange='$jq("#modalSampleReject").data("modalUpdated", true);'>
					</div>
				</div>
			</div>
		</div>
		<br />
	</div>
	<div class="modal-footer">
		<button class="btn btn-primary btn-large"
				data-dismiss="modal"
				id="reject-save"
				disabled="disabled"><bean:message key="label.button.save" /></button>
		&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
		<button class="btn btn-small"
				data-dismiss="modal"
				id="cancel-reject"><bean:message key="label.button.cancel" /></button>
	</div>
</div>

<!-- Modal confirmation popup -->
<div id="confirm-modal" class="sample-modal modal hide fade">
    <div class="modal-header">
      <a href="#" class="close confirm-close" data-dismiss="modal">&times;</a>
      <h3 id="confirm-modal-header-text"><bean:message key="warning.data.not.saved.title" /></h3>
    </div>
    <div class="modal-body">
      <p id="confirm-modal-body-text"><bean:message key="warning.data.not.saved" /></p>
    </div>
    <div class="modal-footer">
		<button class="btn btn-danger" data-dismiss="modal"><bean:message key="label.button.yes" /></button>
		<button class="btn btn-small confirm-close" data-dismiss="modal"><bean:message key="label.button.no" /></button>
    </div>
</div>

<!-- Label Printing Modal -->
<div id="label-modal" class="sample-modal modal hide fade">
    <div class="modal-header">
	   	<button type="button"
	   			class="close"
	   			onclick="cancelPrint()"
	   			data-dismiss="modal">&times;</button>
		<h3><bean:message key="sample.label.print.title" /></h3>
    </div>
    <div class="modal-body">
		<tiles:insert attribute="printLabelsModal"/>
    </div>
    <div class="modal-footer">
    	<button id="printButton"
    		class="btn btn-primary btn-large"
    		disabled="disabled"
    		data-dismiss="modal"
			onclick="submitPrintJob();"
    	><bean:message key="sample.label.print.button"/></button>
		<button class="btn btn-small"
	   			onclick="cancelPrint()"
				data-dismiss="modal"
				id="cancel-printLabels"><bean:message key="label.button.cancel" /></button>
    </div>
</div>

<!-- Warning modal popup, fill in body message before showing -->
<div id="warning-modal" class="sample-modal modal hide fade">
    <div class="modal-header">
      <a href="#" class="close warning-close" data-dismiss="modal">&times;</a>
      <h3 id="warning-modal-header-text"><bean:message key="warning.modal.title" /></h3>
    </div>
    <div class="modal-body">
      <p id="warning-modal-body-text"></p>
    </div>
    <div class="modal-footer">
		<button class="btn btn-small warning-close" data-dismiss="modal"><bean:message key="label.button.ok" /></button>
    </div>
</div>

<!-- Loading modal popup -->
<div id="loading-modal" class="sample-modal modal hide fade">
    <div class="modal-header">
      <a href="#" class="close loading-close" data-dismiss="modal">&times;</a>
      <h3 id="loading-modal-header-text"><bean:message key="loading" /></h3>
    </div>
    <div class="modal-body">
      <img src="images/indicator.gif">
    </div>
    <div class="modal-footer">
    </div>
</div>

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

<html:hidden name="<%=formName%>" property="sampleXML"  styleId="sampleXML"/>
