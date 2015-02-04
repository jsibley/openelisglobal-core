<%@ page language="java"
	contentType="text/html; charset=utf-8"
	import="us.mn.state.health.lims.common.action.IActionConstants,
            us.mn.state.health.lims.common.formfields.FormFields,
            us.mn.state.health.lims.common.formfields.FormFields.Field,
			us.mn.state.health.lims.common.util.Versioning"
%>

<%@ taglib uri="/tags/struts-bean" prefix="bean" %>
<%@ taglib uri="/tags/struts-html" prefix="html" %>
<%@ taglib uri="/tags/struts-logic" prefix="logic" %>
<%@ taglib uri="/tags/labdev-view" prefix="app" %>

<bean:define id="formName" value='<%= (String)request.getAttribute(IActionConstants.FORM_NAME) %>' />
<%!
	String path = "";
	String basePath = "";
%>
<%
	path = request.getContextPath();
	basePath = request.getScheme() + "://" + request.getServerName() + ":"	+ request.getServerPort() + path + "/";
%>

<% if (FormFields.getInstance().useField(Field.SAMPLE_ENTRY_MODAL_VERSION) &&
	   ("SampleEditForm".equals(formName) ||
	    "samplePatientEntryForm".equals(formName) ||
	    "quickEntryForm".equals(formName) ||
	    "sampleLabelPrintForm".equals(formName))) { %>
<link rel="stylesheet" media="screen" type="text/css" href="<%=basePath%>css/bootstrap.min.css?ver=<%= Versioning.getBuildNumber() %>" />
<link rel="stylesheet" media="screen" type="text/css" href="<%=basePath%>css/customBootstrapAdditions.css?ver=<%= Versioning.getBuildNumber() %>" />
<!-- Need to reload the openElisCore stylesheet after loading bootstrap.min.css in order to override certain styles, h1 for example -->
<link rel="stylesheet" media="screen" type="text/css" href="<%=basePath%>css/openElisCore.css?ver=<%= Versioning.getBuildNumber() %>" />
<% } %>

<script type="text/javascript">

function /*void*/ showSuccessMessage( show ){
	$("successMsg").style.visibility = show ? 'visible' : 'hidden';
}

</script>



<div id="successMsg" style="text-align:center; color:seagreen;  width : 100%;font-size:170%; visibility : hidden">
				<bean:message key="save.success"/>
</div>



