<%@ page language="java"
	contentType="text/html; charset=utf-8"
	import="java.util.Calendar,
			java.util.Date,
			java.util.List,
			us.mn.state.health.lims.common.action.IActionConstants,
			us.mn.state.health.lims.common.provider.reports.SampleLabelPrintProvider,
			us.mn.state.health.lims.common.provider.validation.AccessionNumberValidatorFactory,
			us.mn.state.health.lims.common.provider.validation.IAccessionNumberValidator,
	        us.mn.state.health.lims.sample.util.AccessionNumberUtil,
			us.mn.state.health.lims.common.util.ConfigurationProperties,
			us.mn.state.health.lims.common.util.ConfigurationProperties.Property,
			us.mn.state.health.lims.common.util.Versioning" %>

<%@ taglib uri="/tags/struts-bean" prefix="bean" %>
<%@ taglib uri="/tags/struts-html" prefix="html" %>
<%@ taglib uri="/tags/struts-logic" prefix="logic" %>
<bean:define id="formName" value='<%= (String)request.getAttribute(IActionConstants.FORM_NAME) %>' />

<%
	String basePath = "";
	boolean useSpecimenLabels = false;

	String path = request.getContextPath();
	basePath = request.getScheme() + "://" + request.getServerName() + ":"	+ request.getServerPort() + path + "/";
	
	java.util.Locale locale = (java.util.Locale)request.getSession().getAttribute(org.apache.struts.Globals.LOCALE_KEY);
	
	IAccessionNumberValidator accessionNumberValidator = new AccessionNumberValidatorFactory().getValidator();
	
	List<String> printerNames = null;
	SampleLabelPrintProvider sampLblPrnProvider = new SampleLabelPrintProvider();
	if (sampLblPrnProvider != null) {
		printerNames = sampLblPrnProvider.getAllSystemPrintServiceNames();        	
	}

	Calendar cal = Calendar.getInstance();
	int currentYear = cal.get(Calendar.YEAR);
	useSpecimenLabels = ConfigurationProperties.getInstance().isPropertyValueEqual(Property.USE_SPECIMEN_LABELS, "true");
%>

<script type="text/javascript" src="<%=basePath%>scripts/utilities.js?ver=<%= Versioning.getBuildNumber() %>" ></script>
<script type="text/javascript" src="<%=basePath%>scripts/ui/jquery.ui.core.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/ui/jquery.ui.widget.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/ui/jquery.ui.button.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/ui/jquery.ui.position.js?ver=<%= Versioning.getBuildNumber() %>"></script>
<script type="text/javascript" src="<%=basePath%>scripts/ajaxCalls.js?ver=<%= Versioning.getBuildNumber() %>"></script>

<script type="text/javascript">
var invalidPrintElements = new Array();

function isPrintFieldValid(fieldname)
{
    return $jq.inArray(fieldname, invalidPrintElements) == -1;
}

function setPrintFieldInvalid(field)
{
    if( $jq.inArray(field, invalidPrintElements) == -1 )
    {
        invalidPrintElements.push(field);
    }
}

function setPrintFieldValid(field)
{
    var removeIndex = $jq.inArray(field, invalidPrintElements);
    if( removeIndex != -1 )
    {
        for( var i = removeIndex + 1; i < invalidPrintElements.length; i++ )
        {
            invalidPrintElements[i - 1] = invalidPrintElements[i];
        }

        invalidPrintElements.length--;
    }
}

function isPrintEnabled()
{
    return invalidPrintElements.length == 0 && checkRequiredLabelFields();
}

function checkRequiredLabelFields() {
    if (($jq.trim($jq('#labelAccessionNumber').val()).length === 0 &&
    	$jq.trim($jq('#labelAccessionNumber2').val()).length === 0 &&
    	$jq.trim($jq('#accessionCount').val()).length === 0) ||
    	($jq.trim($jq('#masterLabels').val()) < 1
		<% if (useSpecimenLabels) { %>
    	 && $jq.trim($jq('#itemLabels').val()) < 1
    	<% } %>
       ))
    	return false;
    else
    	return true;
}

function checkLabelAccessionNumber( accessionNumber )
{
	//check if empty
	if ( !fieldIsEmptyById( accessionNumber.id ) ) {
		new Ajax.Request (
		   	'ajaxXML',  //url
		   	{//options
		   		method: 'get', //http method
				parameters: 'provider=SampleEntryAccessionNumberValidationProvider&accessionNumber=' + accessionNumber.value + '&field=' + accessionNumber.id +
							'&ignoreYear=false&ignoreUsage=true',
				//indicator: 'throbbing'
				onSuccess:  processLabelAccessionSuccess,
				//onFailure:  processFailure
			}
		);
	} else {
		if (accessionNumber.name != 'accessionRangeEnd') {
			selectFieldErrorDisplay(false, accessionNumber);
			setPrintFieldInvalid(accessionNumber.id);
			alert("<bean:message key="quick.entry.accession.number.required"/>");
			accessionNumber.focus();
		} else {
			selectFieldErrorDisplay(true, accessionNumber);
			setPrintFieldValid(accessionNumber.id);
		}
	}
	setSave();
}

function processLabelAccessionSuccess(xhr) {
	var formField = xhr.responseXML.getElementsByTagName("formfield").item(0).firstChild.nodeValue;
	var message = xhr.responseXML.getElementsByTagName("message").item(0).firstChild.nodeValue;
	var success = false;

	if (message.substring(0,5) == "valid"){
		success = true;
	}

    if (success) {
		selectFieldErrorDisplay(true, $(formField));
		setPrintFieldValid($(formField).id);
    } else {
		selectFieldErrorDisplay(false, $(formField));
		setPrintFieldInvalid($(formField).id);
		alert(message);
		$(formField).focus();
    }
    setSave();
}

function validateLabelAccessionNumber(field) {
	var otherField = $("accessionRangeEnd");
	var	enableFunction = enableAccessionGeneratorFields;

	if (field.value.length == 0) {
		setPrintFieldValid(field.id);
		selectFieldErrorDisplay(true, field);
		if (otherField.value.length == 0) {
			enableFunction(true);
		}
		if (field.id == 'accessionRangeStart')
			validateLabelAccessionNumber2(otherField);
		setSave();
		return;
	}
	makeDirty();
	enableFunction(false);
	checkLabelAccessionNumber(field);
	if (field.id == 'accessionRangeStart')
		validateLabelAccessionNumber2(otherField);
}

function validateLabelAccessionNumber2(field) {
	var otherField = $("accessionRangeStart");

	makeDirty();
	//only validate if not blank (this is not a required field)
	if (field.value != null && field.value != '') {
		enableAccessionGeneratorFields(false);
		//if applicable check to make sure 2nd accessionNumber is > first
		if (otherField.value == null || otherField.value == '' ||
			field.value <= otherField.value) {
			selectFieldErrorDisplay(false, field);
			setPrintFieldInvalid(field.id);
			alert( "<bean:message key="quick.entry.accession.number.bad.order"/>" );
			field.focus();
			setSave();
			return;	
		} else if (otherField.value != null && otherField.value != '' &&
				   field.value.substring(0, <%=AccessionNumberUtil.getInvarientLength()%>) != otherField.value.substring(0, <%=AccessionNumberUtil.getInvarientLength()%>)) {
			selectFieldErrorDisplay(false, field);
			setPrintFieldInvalid(field.id);
			alert( "<bean:message key="sample.label.print.accession.prefix.error"/>" );
			field.focus();
			setSave();
			return;				
		}
		checkLabelAccessionNumber(field);
	} else {
		field.value = '';
		setPrintFieldValid(field.id);
		selectFieldErrorDisplay(true, field);
		if ($F("accessionRangeStart").length == 0) {
			enableAccessionGeneratorFields(true);
		}
      	setSave();
	}
}

function validateCount(field) {
	makeDirty();

	if (field.value != null && field.value != '') {
		enableAccessionRangeFields(false);
	    if (field.value < 1 || !field.value.match(/^\d+$/)) {
			selectFieldErrorDisplay(false, field);
			setPrintFieldInvalid(field.id);
			alert( "<bean:message key="quick.entry.invalid.count"/>" );
			field.focus();
	    } else {
			selectFieldErrorDisplay(true, field);
			setPrintFieldValid(field.id);
	    }
	} else {
		field.value = '';
		enableAccessionRangeFields(true);
		selectFieldErrorDisplay(true, field);
		setPrintFieldValid(field.id);
	}
	setSave();
}

function validateNumber(field) {
	makeDirty();

	if (field.value != null && field.value != '') {
	    if (field.value < 0 || !field.value.match(/^\d+$/)) {
			selectFieldErrorDisplay(false, field);
			setPrintFieldInvalid(field.id);
			alert( "<bean:message key="quick.entry.invalid.number"/> 0" );
			field.focus();
			setSave();
			return;
	    }
	} else {
		field.value = '';
	}
	selectFieldErrorDisplay(true, field);
	setPrintFieldValid(field.id);
  	setSave();
	if ($jq("#label-modal").is(":visible")) $jq("#label-modal").data("modalUpdated", true);
}

function enableAccessionGeneratorFields (flag) {
	if (flag) {
		$("accessionCount").className = '';
		$("accessionCount").disabled = false;
	} else {
		$("accessionCount").className = 'ui-state-disabled';
		$("accessionCount").disabled = true;
	}
}

function enableAccessionRangeFields (flag) {
	if (flag) {
		$("accessionRangeStart").className = '';
		$("accessionRangeEnd").className = '';
		$("accessionRangeStart").disabled = false;
		$("accessionRangeEnd").disabled = false;
	} else {
		$("accessionRangeStart").className = 'ui-state-disabled';
		$("accessionRangeEnd").className = 'ui-state-disabled';
		$("accessionRangeStart").disabled = true;
		$("accessionRangeEnd").disabled = true;
	}
}
</script>

<html:hidden property="labelAccessionNumber" name="<%=formName%>" value="" styleId="labelAccessionNumber"/>
<html:hidden property="labelAccessionNumber2" name="<%=formName%>" value="" styleId="labelAccessionNumber2"/>
<input id="currYear" name="currYear" type="hidden" value=<%=currentYear%> />

<table style="border-spacing:6px;border-collapse:separate">
	<tr> 
		<td>
			<bean:message key="sample.label.print.printerName"/>:<span class="requiredlabel">*</span>
		</td>
		<td>
			<%if(printerNames == null) {%>
			<bean:message key="sample.label.print.printer.input.required"/>			
			<%} else {%>
			<select name="printerName" id="printerName">
				<%for (int i = 0; i < printerNames.size(); i++) {%>								
				<option value="<%= (String) printerNames.get(i)%>">
					<%= printerNames.get(i)%>																	
				</option>
				<%}%>
		    </select>
			<%}%>		 	   	  
		</td>
	</tr>
	<tr>
		<td style="vertical-align:top">
			<bean:message key="sample.label.print.accession.numbers"/>:<span class="requiredlabel">*</span>
		</td>
		<td>
	    	<input style="width:150px" id="accessionRangeStart" type="text" name="accessionRangeStart"
	    	   	onchange="document.forms[0].labelAccessionNumber.value = this.value;validateLabelAccessionNumber(this)" 
			   	maxlength="<%= Integer.toString(accessionNumberValidator.getMaxAccessionLength())%>"/>
	    	<bean:message key="sample.label.print.accession.number.thru"/>&nbsp;
	    	<input style="width:150px" id="accessionRangeEnd" type="text" name="accessionRangeEnd"
	    	   	onchange="document.forms[0].labelAccessionNumber2.value = this.value;validateLabelAccessionNumber2(this)" 
			   	maxlength="<%= Integer.toString(accessionNumberValidator.getMaxAccessionLength())%>"/>
			<br/>
			<i><bean:message key="sample.label.print.accession.option"/></i>
			<br/>
	    	<bean:message key="sample.label.print.accession.count"/>&nbsp;
	    	<input style="width:50px" id="accessionCount" type="text" name="accessionCount"
	    		onchange="validateCount(this)" maxlength="5"/>
		</td>
	</tr>
	<tr> 
		<td>
			<bean:message key="sample.label.print.master.labels"/>:<span class="requiredlabel">*</span>
		</td>
		<td>
			<input style="width:25px" id="masterLabels" type="text" name="masterLabels" maxlength="3" value="1"
				onchange="validateNumber(this)"/>
		</td>
	</tr>
	<% if (useSpecimenLabels) { %>
	<tr> 
		<td>
			<bean:message key="sample.label.print.item.labels"/>:<span class="requiredlabel">*</span>
		</td>
		<td>
			<input style="width:25px" id="itemLabels" type="text" name="itemLabels" maxlength="3" value="1"
				onchange="validateNumber(this)"/>
		</td>
	</tr>
	<% } %>
</table>
