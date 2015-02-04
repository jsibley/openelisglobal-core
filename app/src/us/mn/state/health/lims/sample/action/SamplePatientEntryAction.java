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
* Copyright (C) CIRG, University of Washington, Seattle WA.  All Rights Reserved.
*
*/
package us.mn.state.health.lims.sample.action;

import org.apache.commons.beanutils.PropertyUtils;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;

import us.mn.state.health.lims.common.action.BaseActionForm;
import us.mn.state.health.lims.common.action.IActionConstants;
import us.mn.state.health.lims.common.formfields.FormFields;
import us.mn.state.health.lims.common.services.DisplayListService;
import us.mn.state.health.lims.common.services.DisplayListService.ListType;
import us.mn.state.health.lims.common.services.SampleOrderService;
import us.mn.state.health.lims.common.util.DateUtil;
import us.mn.state.health.lims.common.util.StringUtil;
import us.mn.state.health.lims.patient.action.bean.PatientManagementInfo;
import us.mn.state.health.lims.patient.action.bean.PatientSearch;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * The SampleEntryAction class represents the initial Action for the SampleEntry
 * form of the application
 *
 */
public class SamplePatientEntryAction extends BaseSampleEntryAction {

	protected ActionForward performAction(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response)
			throws Exception {

		String forward = "success";

		request.getSession().setAttribute(IActionConstants.SAVE_DISABLED, IActionConstants.TRUE);

		BaseActionForm dynaForm = (BaseActionForm) form;

		dynaForm.initialize(mapping);

        SampleOrderService sampleOrderService = new SampleOrderService();
        PropertyUtils.setProperty( dynaForm, "sampleOrderItems", sampleOrderService.getSampleOrderItem() );
		PropertyUtils.setProperty(dynaForm, "patientProperties", new PatientManagementInfo());
        PropertyUtils.setProperty( dynaForm, "patientSearch", new PatientSearch() );
		PropertyUtils.setProperty(dynaForm, "sampleTypes", DisplayListService.getList(ListType.SAMPLE_TYPE_ACTIVE));
		PropertyUtils.setProperty(dynaForm, "testSectionList", DisplayListService.getList(ListType.TEST_SECTION));
        PropertyUtils.setProperty( dynaForm, "currentDate", DateUtil.getCurrentDateAsText());
        
        // The following are for compatibility with modal version of sample entry
		PropertyUtils.setProperty(dynaForm, "sampleSources", DisplayListService.getList(ListType.SAMPLE_SOURCE));
		PropertyUtils.setProperty(dynaForm, "initConditionFormErrorsList", DisplayListService.getList(ListType.SAMPLE_ENTRY_INIT_COND_FORM_ERRORS));
		PropertyUtils.setProperty(dynaForm, "initConditionLabelErrorsList", DisplayListService.getList(ListType.SAMPLE_ENTRY_INIT_COND_LABEL_ERRORS));
		PropertyUtils.setProperty(dynaForm, "initConditionMiscList", DisplayListService.getList(ListType.SAMPLE_ENTRY_INIT_COND_MISC));
		PropertyUtils.setProperty(dynaForm, "rejectionReasonFormErrorsList", DisplayListService.getList(ListType.SAMPLE_ENTRY_REJECTION_FORM_ERRORS));
		PropertyUtils.setProperty(dynaForm, "rejectionReasonLabelErrorsList", DisplayListService.getList(ListType.SAMPLE_ENTRY_REJECTION_LABEL_ERRORS));
		PropertyUtils.setProperty(dynaForm, "rejectionReasonMiscList", DisplayListService.getList(ListType.SAMPLE_ENTRY_REJECTION_MISC));

		addProjectList( dynaForm );

		if (FormFields.getInstance().useField(FormFields.Field.InitialSampleCondition)) {
			PropertyUtils.setProperty(dynaForm, "initialSampleConditionList", DisplayListService.getList(ListType.INITIAL_SAMPLE_CONDITION));
		}

		if (FormFields.getInstance().useField(FormFields.Field.SAMPLE_ENTRY_ORDER_URGENCY)) {
			PropertyUtils.setProperty(dynaForm, "sampleOrderItems.orderUrgency", StringUtil.getContextualMessageForKey("patient.normal"));
		}

		return mapping.findForward(forward);
	}

}
