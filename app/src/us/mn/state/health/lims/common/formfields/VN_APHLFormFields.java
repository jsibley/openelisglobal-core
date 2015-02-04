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
*
* Contributor(s): CIRG, University of Washington, Seattle WA.
*/
package us.mn.state.health.lims.common.formfields;

import java.util.HashMap;

import us.mn.state.health.lims.common.formfields.FormFields.Field;

public class VN_APHLFormFields implements IFormFieldsForImplementation {

	public HashMap<Field, Boolean> getImplementationAttributes() {
		HashMap<Field, Boolean> settings = new HashMap<Field, Boolean>();
		settings.put(Field.ADDRESS_DISTRICT, Boolean.TRUE);
		settings.put(Field.ADDRESS_WARD, Boolean.TRUE);
		settings.put(Field.ADDRESS_CITY, Boolean.FALSE);
		settings.put(Field.ADDRESS_DEPARTMENT, Boolean.FALSE);
		settings.put(Field.ADDRESS_VILLAGE, Boolean.FALSE);
		settings.put(Field.AKA, Boolean.FALSE);
		settings.put(Field.CollectionDate, Boolean.TRUE);
		settings.put(Field.ADDRESS_COMMUNE, Boolean.TRUE);
		settings.put(Field.DepersonalizedResults, Boolean.TRUE);
		settings.put(Field.EXTERNAL_ID, Boolean.TRUE);
		settings.put(Field.EXTERNAL_ID_REQUIRED, Boolean.TRUE);
		settings.put(Field.InitialSampleCondition, Boolean.TRUE);
		settings.put(Field.InlineOrganizationTypes, Boolean.TRUE);
        settings.put(Field.LAB_NUMBER_USED_ONLY_IF_SPECIMENS, Boolean.TRUE);
		settings.put(Field.LINK_DISTRICTS_TO_CITIES, Boolean.TRUE);
		settings.put(Field.MLS, Boolean.FALSE);
		settings.put(Field.MothersName, Boolean.FALSE);
		settings.put(Field.OrganizationCLIA, Boolean.FALSE);
		settings.put(Field.OrganizationMultiUnit, Boolean.FALSE);
		settings.put(Field.OrganizationOrgId, Boolean.FALSE);
		settings.put(Field.OrganizationParent, Boolean.FALSE);
		settings.put(Field.OrganizationShortName, Boolean.TRUE);
		settings.put(Field.OrgLocalAbrev, Boolean.TRUE);
		settings.put(Field.OrgState, Boolean.FALSE);
        settings.put(Field.PATIENT_CITY_PICKLIST, Boolean.TRUE);
		settings.put(Field.PatientHealthDistrict, Boolean.FALSE);
		settings.put(Field.PatientRequired, Boolean.TRUE);
		settings.put(Field.PROJECT_OR_NAME, Boolean.TRUE);
		settings.put(Field.PROJECT2_OR_NAME, Boolean.TRUE);
        settings.put(Field.SAMPLE_ENTRY_COMPACT_LAYOUT, Boolean.TRUE);
		settings.put(Field.SAMPLE_ENTRY_MEDICAL_RECORD_CHART_NUMBER, Boolean.TRUE);
        settings.put(Field.SAMPLE_ENTRY_MODAL_VERSION, Boolean.TRUE);
        settings.put(Field.SAMPLE_ENTRY_ORDER_URGENCY, Boolean.TRUE);
        settings.put(Field.SAMPLE_ENTRY_PATIENT_AGE_VALUE_AND_UNITS, Boolean.TRUE);
		settings.put(Field.SAMPLE_ENTRY_PATIENT_BED_NUMBER, Boolean.TRUE);
        settings.put(Field.SAMPLE_ENTRY_PATIENT_CLINICAL_DEPT, Boolean.TRUE);
        settings.put(Field.SAMPLE_ENTRY_PATIENT_DIAGNOSIS, Boolean.TRUE);
		settings.put(Field.SAMPLE_ENTRY_PATIENT_EMPLOYER_NAME, Boolean.TRUE);
		settings.put(Field.SAMPLE_ENTRY_PATIENT_ROOM_NUMBER, Boolean.TRUE);
        settings.put(Field.SAMPLE_ENTRY_REJECTION_IN_MODAL_VERSION, Boolean.TRUE);
        settings.put(Field.SAMPLE_ENTRY_REQUESTER_WORK_PHONE_AND_EXT, Boolean.TRUE);
        settings.put(Field.SampleCondition, Boolean.TRUE);
        settings.put(Field.SampleEntryRequestingSiteSampleId, Boolean.FALSE);
		settings.put(Field.SampleEntryUseReceptionHour, Boolean.TRUE);
		settings.put(Field.SampleEntryUseRequestDate, Boolean.FALSE);
        settings.put(Field.SINGLE_NAME_FIELD, Boolean.TRUE);
		settings.put(Field.StNumber, Boolean.FALSE);
		settings.put(Field.SUBMITTER_NUMBER, Boolean.TRUE);
        settings.put(Field.ValueHozSpaceOnResults, Boolean.TRUE);
		settings.put(Field.ZipCode, Boolean.FALSE);
		return settings;
	}

}
