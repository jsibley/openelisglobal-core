/**
* The contents of this file are subject to the Mozilla Public License
* Version 1.1 (the "License"); you may not use this file except in
* compliance with the License. You may obtain a copy of the License at
* http://www.mozilla.org/MPL/ 
* 
* Software distributed under the License is distributed on an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
* License for the specific language governing rights and limitations under
* the License.
* 
* The Original Code is OpenELIS code.
* 
* Copyright (C) The Minnesota Department of Health.  All Rights Reserved.
*/
package us.mn.state.health.lims.sample.action;

import org.apache.struts.Globals;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.action.ActionMessages;
import us.mn.state.health.lims.common.action.BaseAction;
import us.mn.state.health.lims.common.action.BaseActionForm;
import us.mn.state.health.lims.common.provider.reports.SampleLabelPrintProvider;
import us.mn.state.health.lims.common.util.SystemConfiguration;
import us.mn.state.health.lims.common.util.validator.ActionError;
import us.mn.state.health.lims.login.valueholder.UserSessionData;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * @author diane benz
 * 
 * To change this generated comment edit the template variable "typecomment":
 * Window>Preferences>Java>Templates. To enable and disable the creation of type
 * comments go to Window>Preferences>Java>Code Generation.
 *
 * bugzilla 2167: added message indicating which accession numbers had their label printed
 */
public class SampleLabelPrintProcessAction extends BaseAction {


	protected ActionForward performAction(ActionMapping mapping,
			ActionForm form, HttpServletRequest request,
			HttpServletResponse response) throws Exception {

		String forward = FWD_SUCCESS;
		request.setAttribute(ALLOW_EDITS_KEY, "true");

		BaseActionForm dynaForm = (BaseActionForm) form;
		UserSessionData usd = (UserSessionData)request.getSession().getAttribute(USER_SESSION_DATA);
		String accessionCount = (String)dynaForm.get("accessionCount");
		String accessionStart = (String)dynaForm.get("labelAccessionNumber");
		String accessionEnd = (String)dynaForm.get("labelAccessionNumber2");
		String printerName = (String)dynaForm.get("printerName");
		String masterLabels = (String)dynaForm.get("masterLabels");
		String itemLabels = (String)dynaForm.get("itemLabels");

		ActionMessages errors = new ActionMessages();

		SampleLabelPrintProvider printProvider = new SampleLabelPrintProvider();
		String result = "";

		if (!SystemConfiguration.getInstance().getLabelPrinterName().equalsIgnoreCase(NO_LABEL_PRINTING) && !SystemConfiguration.getInstance().getLabelPrinterName().equals(BLANK)) {
			result = printProvider.printLabels(request, usd, accessionCount, accessionStart, accessionEnd, printerName, masterLabels, itemLabels);
		} 

		if (result.equals(FWD_FAIL_MAX_LABELS_EXCEED)) {
			ActionError error = new ActionError("errors.labelprint.exceeded.maxnumber", SystemConfiguration.getInstance().getMaxNumberOfLabels(), null);
			errors.add(ActionMessages.GLOBAL_MESSAGE, error);
		}

		if (result.equals(FWD_FAIL_BAD_PRINTER)) {
			ActionError error = new ActionError("errors.labelprint.no.printer", null);
			errors.add(ActionMessages.GLOBAL_MESSAGE, error);
		}

		if (result.equals(FWD_FAIL)) {
			ActionError error = new ActionError("errors.labelprint.general.error", null);
			errors.add(ActionMessages.GLOBAL_MESSAGE, error);
		}

		if (errors.size() > 0) {
			saveErrors(request, errors);
			// since we forward to jsp - not Action we don't need to repopulate
			// the lists here
			request.setAttribute(Globals.ERROR_KEY, errors);
			return mapping.findForward(FWD_FAIL);
		}

		setSuccessFlag(request, forward);
		request.setAttribute("zplData", result);
		return mapping.findForward(forward);
	}
	
	protected String getPageTitleKey() {
		return "sample.label.print.title";
	}

	protected String getPageSubtitleKey() {
		return "sample.label.print.title";
	}

}