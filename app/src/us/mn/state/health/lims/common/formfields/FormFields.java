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

import java.util.Map;

/*
 * These are different fields on the forms which can be turned on and off by configuration.
 * Note that the administration menu is in it's own class because it is a big area confined to it a single page
 */
public class FormFields {
	//Note- these should all be upper case, change as you touch and add form name to name
	public static enum Field {
		AKA,                                    //Include AKA with patient info
		StNumber,                               //Include ST number with patient info
		MothersName,                            //Include Mothers name with patient info
		PatientType,                            //Include patient type with patient info
		InsuranceNumber,                        //Include patient insurance number will patient info
		CollectionDate,                         //Track collection date for samples, current date will be used if false
		CollectionTime,                         //Track collection time for samples
		RequesterSiteList,                      //Present list of referring sites
		OrgLocalAbrev,                          //Use organization abbreviation.  Should be standardized to FALSE
		OrgState,                               //Include state in organization info
		ZipCode,                                //Include zip code in organization info
		MLS,                                    //Include indicator if organization is a sentinel lab
		InlineOrganizationTypes,                //Should organization types be included when specifying organizations
		SubjectNumber,                          //Include subject number with patient info
        SubjectNumberRequired,                  //If using subject number is it required
		ProviderInfo,                           //Include provider information on order form
		NationalID,                             //Include national ID with patient info
		Occupation,                             //Include occupation with patient info
		MotherInitial,                          //Include mothers first initial with patient info
		SearchSampleStatus,                     //Can patients be searched for by status
		OrganizationAddressInfo,                //Include address info with organization info
		OrganizationCLIA,                       //Include CLIA status with organization info
		OrganizationParent,                     //Include parent with organization info
		OrganizationShortName,                  //Include short name with organization info
		OrganizationMultiUnit,                  //Include multiunit status with organization address info
		OrganizationOrgId,                      //Include db id with organization info
		Project,                                //Include project (RETROCI) with non-conformity info
		PROJECT_OR_NAME,                        //Include project (VN) with order request info
		PROJECT2_OR_NAME,                       //Include secondary project (VN) with order request info
		SUBMITTER_NUMBER,                       //Include submitter number (VN) with order request info
		EXTERNAL_ID,                       		//Include external ID (VN) with patient info
		EXTERNAL_ID_REQUIRED,              		//Should external ID (VN) be required
		SampleCondition,                        //Allow for collection of sample condition with non-conformity
		NON_CONFORMITY_SITE_LIST,               // site (patient entry or nonconforming) is defined by a list of sites.
		NON_CONFORMITY_SITE_LIST_USER_ADDABLE,  //Should the user be able to add to the site list
		NON_CONFORMITY_PROVIDER_ADDRESS,        //Should the providers address be collected on non-conformity page
        ADDRESS_CITY,                            //Is a city part of an address
        ADDRESS_DEPARTMENT,                      //Is department part of an address
        ADDRESS_COMMUNE,                         //Is a commune part of an address
        ADDRESS_VILLAGE,                         //Is a village part of an address
		ADDRESS_DISTRICT,						//Is a district part of an address (as in VN)
		ADDRESS_WARD,							//Is a ward part of an address (as in VN)
		LINK_DISTRICTS_TO_CITIES,				//Populate district list based on selected city (as in VN)
		DepersonalizedResults,                  //Should results entry have personal identifiers
		SEARCH_PATIENT_WITH_LAB_NO,             //Should lab number be part of patient search
		ResultsReferral,                        //Can results be referred out
		ValueHozSpaceOnResults,                 //favors a layout which values horizontal space over vertical space
		InitialSampleCondition,                 //Allow for collection of sample condition with sample entry
		PatientRequired,                        // By default, a (minimal) patient to go with a sample is required.
		PatientRequired_SampleConfirmation,     //Is patient required for sample confirmation
        QA_FULL_PROVIDER_INFO,                     //Include provider information on non-conformity
        QA_REQUESTER_SAMPLE_ID,                 //If provider info is used on non-conformity should it include provider sample id
		QASubjectNumber,                        //Include subject number be on non-conformity
		QATimeWithDate,                         //Include time in addition to date on non-conformity
		PatientIDRequired,                      //Is patient ID required for patient
		PatientIDRequired_SampleConfirmation,   //Is patient ID required for patient on sample conformation form
		PatientNameRequired,                    //Is patient name required
		SampleEntryUseReceptionHour,            //Include reception time on sample entry
		SampleEntryUseRequestDate,              //Include request date on sample entry
		SampleEntryNextVisitDate,               //Include next visit date on sample entry
		SampleEntryRequestingSiteSampleId,      //Include sample ID from requesting site
		SampleEntryReferralSiteNameRequired,    //Is referral site required
		SampleEntryReferralSiteNameCapitialized,//Should referral site name be transformed to upper case
		SampleEntryReferralSiteCode,            //Include referral site code on sample entry
		SampleEntryProviderFax,                 //Include provider fax for sample entry
		SampleEntryProviderEmail,               //Include provider email for sample entry
		SampleEntryHealthFacilityAddress,       //Include referral address
		SampleEntrySampleCollector,             //Include name of sample collector
		SampleEntryRequesterLastNameRequired,   //Is the requester name required
		SAMPLE_ENTRY_USE_REFFERING_PATIENT_NUMBER,//Include referral patient number
		SAMPLE_ENTRY_MODAL_VERSION,				//Should the modal version for specimen/test selection be used on the sample entry screen, as used in VN?
		SAMPLE_ENTRY_REJECTION_IN_MODAL_VERSION,//Should rejection be allowed in the modal version of specimen/test selection, as used in VN?
		SINGLE_NAME_FIELD,						//Should there only be one name entry field (with data stored in the 'first_name' db column, as used in VN)?
		PATIENT_CITY_PICKLIST,					//Should the patient management city input be rendered as a picklist instead of text, as used in VN?
		SAMPLE_ENTRY_REQUESTER_WORK_PHONE_AND_EXT,//Should the order requester work phone and extension be two separate fields, as used in VN?
		SAMPLE_ENTRY_ORDER_URGENCY,				//Include patient/order urgency on sample entry, as used in VN?
		SAMPLE_ENTRY_PATIENT_CLINICAL_DEPT,		//Include patient department where test was ordered from (as in VN)
		SAMPLE_ENTRY_PATIENT_AGE_VALUE_AND_UNITS,//Should there be two fields to collect patient age (value and units) not linked to the birthdate field, as used in VN?
		SAMPLE_ENTRY_PATIENT_DIAGNOSIS,			//Include patient diagnosis on sample entry (as in VN)
		SAMPLE_ENTRY_PATIENT_BED_NUMBER,		//Include patient bed number on sample entry (as in VN)
		SAMPLE_ENTRY_PATIENT_ROOM_NUMBER,		//Include patient room number on sample entry (as in VN)
		SAMPLE_ENTRY_PATIENT_EMPLOYER_NAME,		//Include patient's employer's name on sample entry (as in VN)
		SAMPLE_ENTRY_MEDICAL_RECORD_CHART_NUMBER,//Include medical record/chart number on sample entry (as in VN)
		SAMPLE_ENTRY_COMPACT_LAYOUT,			//Should the sample entry page be as compact as possible (more width, less length), as used in VN?
		LAB_NUMBER_USED_ONLY_IF_SPECIMENS,		//Should accession number be considered 'used' only if it has specimens associated with it, as used in VN?
		PatientPhone,                           //Include patient phone with patient info
		PatientHealthRegion,                    //Include patient health region with patient info
		PatientHealthDistrict,                  //Include patient health district with patient info
		PatientNationality,                     //Include patient nationality with patient info
		PatientMarriageStatus,                  //Include patient marriage status with patient info
		PatientEducation,                       //Include patient education level with patient info
		SampleEntryPatientClinical,             //Include patient clinical information on sample entry (request by CI but not currently implemented)
		QA_DOCUMENT_NUMBER,                      //Include document number on non-conformity
        TEST_LOCATION_CODE                      //Include test location code on order entry
	}

	private static FormFields instance = null;

	private Map<FormFields.Field, Boolean> fields;

	private FormFields(){
		fields = new DefaultFormFields().getFieldFormSet();
	}

	public static FormFields getInstance(){
		if( instance == null){
			instance = new FormFields();
		}

		return instance;
	}

	public boolean useField( FormFields.Field field){
		return fields.get(field);
	}
}
