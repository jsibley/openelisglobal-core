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
package us.mn.state.health.lims.sample.action;

import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.validator.GenericValidator;
import org.apache.struts.Globals;
import org.apache.struts.action.ActionErrors;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.action.ActionMessages;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.DocumentHelper;
import org.dom4j.Element;
import org.hibernate.StaleObjectStateException;
import org.hibernate.Transaction;

import us.mn.state.health.lims.analysis.dao.AnalysisDAO;
import us.mn.state.health.lims.analysis.daoimpl.AnalysisDAOImpl;
import us.mn.state.health.lims.analysis.valueholder.Analysis;
import us.mn.state.health.lims.common.action.BaseAction;
import us.mn.state.health.lims.common.action.BaseActionForm;
import us.mn.state.health.lims.common.exception.LIMSRuntimeException;
import us.mn.state.health.lims.common.formfields.FormFields;
import us.mn.state.health.lims.common.formfields.FormFields.Field;
import us.mn.state.health.lims.common.log.LogEvent;
import us.mn.state.health.lims.common.provider.validation.IAccessionNumberValidator;
import us.mn.state.health.lims.common.provider.validation.IAccessionNumberValidator.ValidationResults;
import us.mn.state.health.lims.common.provider.validation.OrganizationLocalAbbreviationValidationProvider;
import us.mn.state.health.lims.common.services.ObservationHistoryService;
import us.mn.state.health.lims.common.services.SampleAddService;
import us.mn.state.health.lims.common.services.SampleAddService.SampleTestCollection;
import us.mn.state.health.lims.common.services.StatusService;
import us.mn.state.health.lims.common.services.StatusService.AnalysisStatus;
import us.mn.state.health.lims.common.services.StatusService.OrderStatus;
import us.mn.state.health.lims.common.util.DateUtil;
import us.mn.state.health.lims.common.util.SystemConfiguration;
import us.mn.state.health.lims.common.util.validator.ActionError;
import us.mn.state.health.lims.hibernate.HibernateUtil;
import us.mn.state.health.lims.observationhistory.dao.ObservationHistoryDAO;
import us.mn.state.health.lims.observationhistory.daoimpl.ObservationHistoryDAOImpl;
import us.mn.state.health.lims.observationhistory.valueholder.ObservationHistory;
import us.mn.state.health.lims.organization.dao.OrganizationDAO;
import us.mn.state.health.lims.organization.daoimpl.OrganizationDAOImpl;
import us.mn.state.health.lims.organization.valueholder.Organization;
import us.mn.state.health.lims.panel.valueholder.Panel;
import us.mn.state.health.lims.patient.action.PatientManagementUpdateAction;
import us.mn.state.health.lims.patient.action.bean.PatientManagementInfo;
import us.mn.state.health.lims.patient.dao.PatientDAO;
import us.mn.state.health.lims.patient.daoimpl.PatientDAOImpl;
import us.mn.state.health.lims.patient.util.PatientUtil;
import us.mn.state.health.lims.patient.valueholder.Patient;
import us.mn.state.health.lims.project.dao.ProjectDAO;
import us.mn.state.health.lims.project.daoimpl.ProjectDAOImpl;
import us.mn.state.health.lims.project.valueholder.Project;
import us.mn.state.health.lims.requester.dao.RequesterTypeDAO;
import us.mn.state.health.lims.requester.dao.SampleRequesterDAO;
import us.mn.state.health.lims.requester.daoimpl.RequesterTypeDAOImpl;
import us.mn.state.health.lims.requester.daoimpl.SampleRequesterDAOImpl;
import us.mn.state.health.lims.requester.valueholder.RequesterType;
import us.mn.state.health.lims.requester.valueholder.SampleRequester;
import us.mn.state.health.lims.sample.dao.SampleDAO;
import us.mn.state.health.lims.sample.daoimpl.SampleDAOImpl;
import us.mn.state.health.lims.sample.util.AccessionNumberUtil;
import us.mn.state.health.lims.sample.valueholder.Sample;
import us.mn.state.health.lims.samplehuman.dao.SampleHumanDAO;
import us.mn.state.health.lims.samplehuman.daoimpl.SampleHumanDAOImpl;
import us.mn.state.health.lims.samplehuman.valueholder.SampleHuman;
import us.mn.state.health.lims.sampleitem.dao.SampleItemDAO;
import us.mn.state.health.lims.sampleitem.daoimpl.SampleItemDAOImpl;
import us.mn.state.health.lims.sampleproject.dao.SampleProjectDAO;
import us.mn.state.health.lims.sampleproject.daoimpl.SampleProjectDAOImpl;
import us.mn.state.health.lims.sampleproject.valueholder.SampleProject;
import us.mn.state.health.lims.test.dao.TestDAO;
import us.mn.state.health.lims.test.daoimpl.TestDAOImpl;
import us.mn.state.health.lims.test.valueholder.Test;
import us.mn.state.health.lims.test.valueholder.TestSection;

public class QuickEntrySaveAction extends BaseAction {

	private static final String DEFAULT_ANALYSIS_TYPE = "MANUAL";
	public static  long ORGANIZATION_REQUESTER_TYPE_ID;
	private String patientId;
	private String accessionNumber;
	private String[] accList;
	private String projectId;
	private Sample sample;
	private SampleDAO sampleDAO = new SampleDAOImpl();
	private SampleHumanDAO sampleHumanDAO = new SampleHumanDAOImpl();
	private SampleHuman sampleHuman;
	private SampleRequester requesterSite;
	private PatientManagementUpdateAction patientUpdate;
	private List<SampleTestCollection> sampleItemsTests;
    private List<ObservationHistory> observations  = new ArrayList<ObservationHistory>();
	private SampleAddService sampleAddService;
	private ActionMessages errors = new ActionMessages();
	private ActionMessages patientErrors = new ActionMessages();
	private boolean useReceiveDateForCollectionDate = false;
	private String collectionDateFromRecieveDate = null;
	private boolean isNewSample;
	private Map<String, PatientManagementInfo> patientMap = new HashMap<String, PatientManagementInfo>();
	private Map<String, String> referringIdMap = new HashMap<String, String>();

	static {
		RequesterTypeDAO requesterTypeDAO = new RequesterTypeDAOImpl();
		RequesterType type = requesterTypeDAO.getRequesterTypeByName("organization");
		if (type != null) {
			ORGANIZATION_REQUESTER_TYPE_ID = Long.parseLong(type.getId());
		}
	}

	@Override
	protected ActionForward performAction(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response)
			throws Exception {

		String forward = FWD_SUCCESS;

		boolean useInitialSampleCondition = FormFields.getInstance().useField(Field.InitialSampleCondition);
		BaseActionForm dynaForm = (BaseActionForm) form;

		String receivedDateForDisplay = dynaForm.getString("receivedDateForDisplay");
		useReceiveDateForCollectionDate = !FormFields.getInstance().useField(Field.CollectionDate);

		String receivedTime = dynaForm.getString("receivedTime");
		if (!GenericValidator.isBlankOrNull(receivedTime)) {
			receivedDateForDisplay += " " + receivedTime;
		} else {
			receivedDateForDisplay += " 00:00";
		}

		if (useReceiveDateForCollectionDate) {
			collectionDateFromRecieveDate = receivedDateForDisplay;
		}

		String projectIdOrName = dynaForm.getString("projectIdOrName");
		String projectIdOrNameOther = dynaForm.getString("projectIdOrNameOther");
		if (!GenericValidator.isBlankOrNull(projectIdOrName) && org.apache.commons.lang.StringUtils.isNumeric(projectIdOrName)) {
			projectId = projectIdOrName;
		} else if (!GenericValidator.isBlankOrNull(projectIdOrNameOther) && org.apache.commons.lang.StringUtils.isNumeric(projectIdOrNameOther)) {
			projectId = projectIdOrNameOther;
		} else {
			projectId = null;
		}
		
		String sampleOrgLocalAbbrev = dynaForm.getString("submitterNumber");
		if (!GenericValidator.isBlankOrNull(sampleOrgLocalAbbrev)) {
			ActionError orgError = validateOrgData(sampleOrgLocalAbbrev);
			if (orgError == null) {
				OrganizationDAO orgDAO = new OrganizationDAOImpl();
				Organization organization = new Organization();
				organization.setOrganizationLocalAbbreviation(sampleOrgLocalAbbrev);
				requesterSite = createSiteRequester(orgDAO.getOrganizationByLocalAbbreviation(organization, true).getId());
			} else {
				errors.add(ActionErrors.GLOBAL_MESSAGE, orgError);
			}
		}

		String accessions = (String) dynaForm.getString("accessionList");
		accList = accessions.split(",");

		if (!GenericValidator.isBlankOrNull(dynaForm.getString("patientXML"))) {
			parsePatientData(dynaForm, mapping, request);
		}
		
		for (int i = 0; i < accList.length; i++) {
			accessionNumber = accList[i];
			populatePatientData(mapping, request, false);
			if (i == 0)
				initSampleData(dynaForm, receivedDateForDisplay);
			sample.setAccessionNumber(accessionNumber);
			sample.setReferringId(referringIdMap.get(accessionNumber));
			validateSample();
		}
		
		if (errors.size() > 0) {
			saveErrors(request, errors);
			request.setAttribute(Globals.ERROR_KEY, errors);
			return mapping.findForward(FWD_FAIL);
		}

		Transaction tx = HibernateUtil.getSession().beginTransaction();

		try {
			for (int i = 0; i < accList.length; i++) {
				accessionNumber = accList[i];
				createPopulatedSample(dynaForm, receivedDateForDisplay);
				populatePatientData(mapping, request, true);
				sample.setAccessionNumber(accessionNumber);
				sample.setReferringId(referringIdMap.get(accessionNumber));

				persistPatientData();
				persistSampleData();
				if (useInitialSampleCondition) {
					persistInitialSampleConditions();
				}
				persistObservations();
				
				if (!GenericValidator.isBlankOrNull(sampleOrgLocalAbbrev))
					persistRequesterData();
			}
			tx.commit();
		} catch (LIMSRuntimeException lre) {
			tx.rollback();

			ActionError error = null;
			if (lre.getException() instanceof StaleObjectStateException) {
				error = new ActionError("errors.OptimisticLockException", null, null);
			} else {
				lre.printStackTrace();
				error = new ActionError("errors.UpdateException", null, null);
			}

			errors.add(ActionMessages.GLOBAL_MESSAGE, error);
			saveErrors(request, errors);
			request.setAttribute(Globals.ERROR_KEY, errors);
			request.setAttribute(ALLOW_EDITS_KEY, "false");
			return mapping.findForward(FWD_FAIL);

		} finally {
			HibernateUtil.closeSession();
		}

		setSuccessFlag(request, forward);

		return mapping.findForward(forward);
	}

	private ActionError validateOrgData(String sampleOrgLocalAbbrev) {
		ActionError error = null;
		if (org.apache.commons.lang.StringUtils.isNumeric(sampleOrgLocalAbbrev)) {
			OrganizationLocalAbbreviationValidationProvider orgValidator = new OrganizationLocalAbbreviationValidationProvider();
			if (orgValidator.validate(sampleOrgLocalAbbrev, null).startsWith(INVALID)) {
				error = new ActionError("error.organization.unknown");
			}
		} else {
			error = new ActionError("error.organization.unknown");
		}
		return error;
	}

	private SampleRequester createSiteRequester(String orgId) {
		SampleRequester requester;
		requester = new SampleRequester();
		requester.setRequesterId(orgId);
		requester.setRequesterTypeId(ORGANIZATION_REQUESTER_TYPE_ID);
		requester.setSysUserId(currentUserId);
		return requester;
	}

	private void validateSample() {
		// assure accession number(s)
		ValidationResults formatResult = AccessionNumberUtil.correctFormat(accessionNumber, true);
		boolean usedResult = AccessionNumberUtil.isUsed(accessionNumber);

		if (formatResult != IAccessionNumberValidator.ValidationResults.SUCCESS || usedResult) {
			String message = AccessionNumberUtil.getInvalidMessage(formatResult);
			errors.add(ActionErrors.GLOBAL_MESSAGE, new ActionError(message));
		}
		
		// assure that there is at least 1 sample
		if (sampleItemsTests.isEmpty()) {
			errors.add(ActionErrors.GLOBAL_MESSAGE, new ActionError("errors.no.sample"));
		}

		// assure that all samples have tests
		if (!allSamplesHaveTests()) {
			errors.add(ActionErrors.GLOBAL_MESSAGE, new ActionError("errors.samples.with.no.tests"));
		}

		// check patient errors
		if (patientErrors.size(ActionErrors.GLOBAL_MESSAGE) > 0) {
			errors.add(patientErrors);
		}

	}

	private boolean allSamplesHaveTests() {

		for (SampleTestCollection sampleTest : sampleItemsTests) {
			if (sampleTest.tests.size() == 0) {
				return false;
			}
		}

		return true;
	}

	private void initSampleData(BaseActionForm dynaForm, String receivedDate) {
		createPopulatedSample(dynaForm, receivedDate);

		sampleAddService = new SampleAddService(dynaForm.getString("sampleXML"), currentUserId, sample, receivedDate);
		sampleItemsTests = sampleAddService.createSampleTestCollection();
	}

	private void createPopulatedSample(BaseActionForm dynaForm, String receivedDate) {
		sample = new Sample();
		isNewSample = true;

		// Check for existing sample
		Sample existingSample = sampleDAO.getSampleByAccessionNumber(accessionNumber);
		if (existingSample != null && !GenericValidator.isBlankOrNull(existingSample.getId())) {
			sample.setId(existingSample.getId());
			sampleDAO.getData(sample);
			isNewSample = false;
		}
		
		sample.setSysUserId(currentUserId);
		sample.setEnteredDate(DateUtil.getNowAsSqlDate());
        sample.setReceivedTimestamp(DateUtil.convertStringDateToTimestamp(receivedDate));

		if (useReceiveDateForCollectionDate) {
			sample.setCollectionDateForDisplay(collectionDateFromRecieveDate);
		}

		sample.setDomain(SystemConfiguration.getInstance().getHumanDomain());
		sample.setStatusId(StatusService.getInstance().getStatusID(OrderStatus.Entered));
	}

    private void createObservation(String observationData, String observationType, ObservationHistory.ValueType valueType) {
        if (!GenericValidator.isBlankOrNull(observationData) && !GenericValidator.isBlankOrNull(observationType)) {
            ObservationHistory observation = new ObservationHistory();
            observation.setObservationHistoryTypeId(observationType);
            observation.setSysUserId(currentUserId);
            observation.setValue(observationData);
            observation.setValueType(valueType);
            observations.add(observation);
        }
    }

	private void parsePatientData(BaseActionForm dynaForm, ActionMapping mapping, HttpServletRequest request) {
		try {
			Document patientDom = DocumentHelper.parseText(dynaForm.getString("patientXML"));
			for (@SuppressWarnings("rawtypes") Iterator i = patientDom.getRootElement().elementIterator("patient"); i.hasNext();) {
				Element patient = (Element)i.next();
				PatientManagementInfo patientInfo = new PatientManagementInfo();
				patientInfo.setBirthDateForDisplay(patient.attributeValue("patientDob"));
				patientInfo.setPatientProcessingStatus("add");
				if (FormFields.getInstance().useField(FormFields.Field.SAMPLE_ENTRY_PATIENT_AGE_VALUE_AND_UNITS) &&
					!GenericValidator.isBlankOrNull(patient.attributeValue("patientAge"))) {
					createObservation(patient.attributeValue("patientAge"), ObservationHistoryService.getObservationTypeIdForType(ObservationHistoryService.ObservationType.PATIENT_AGE_VALUE), ObservationHistory.ValueType.LITERAL);
					createObservation("Years", ObservationHistoryService.getObservationTypeIdForType(ObservationHistoryService.ObservationType.PATIENT_AGE_UNITS), ObservationHistory.ValueType.LITERAL);
				} else {
					patientInfo.setAge(patient.attributeValue("patientAge"));
				}
				patientInfo.setGender(patient.attributeValue("patientGender"));
				patientInfo.setNationalId(patient.element("patientID").getText());
				patientInfo.setFirstName(patient.element("patientFirstName").getText());
				patientInfo.setLastName(patient.element("patientLastName").getText());
				
				referringIdMap.put(patient.attributeValue("accNo"),
								   GenericValidator.isBlankOrNull(patient.element("referringID").getText()) ? null : patient.element("referringID").getText());
				if (!GenericValidator.isBlankOrNull(patientInfo.getBirthDateForDisplay()) ||
					!GenericValidator.isBlankOrNull(patientInfo.getAge()) ||
					!GenericValidator.isBlankOrNull(patientInfo.getGender()) ||
					!GenericValidator.isBlankOrNull(patientInfo.getNationalId()) ||
					!GenericValidator.isBlankOrNull(patientInfo.getFirstName()) ||
					!GenericValidator.isBlankOrNull(patientInfo.getLastName()))
					patientMap.put(patient.attributeValue("accNo"), patientInfo);
			}
		} catch (DocumentException e) {
			e.printStackTrace();
			LogEvent.logError("QuickEntrySaveAction","parsePatientData()", e.toString());
			patientErrors.add(ActionMessages.GLOBAL_MESSAGE, new ActionError("error.parsing.xml", null, null));
		}
	}

	private void populatePatientData(ActionMapping mapping, HttpServletRequest request, boolean forPersist)
			throws NoSuchMethodException, InvocationTargetException, IllegalAccessException {
		Patient existingPatient = null;

		if (patientMap.get(accessionNumber) != null) { 
			patientUpdate = new PatientManagementUpdateAction();
			PatientManagementInfo patientInfo = patientMap.get(accessionNumber);
			if (forPersist && !isNewSample) {
				existingPatient = sampleHumanDAO.getPatientForSample(sample);
				patientInfo.setPatientPK(existingPatient.getId());
				patientInfo.setPatientProcessingStatus("update");
			}
			patientUpdate.setPatientUpdateStatus(patientInfo);
			patientErrors.add(patientUpdate.preparePatientData(mapping, request, patientInfo));
		}
	}
	
    private void persistObservations() {

        ObservationHistoryDAO observationDAO = new ObservationHistoryDAOImpl();
		for (ObservationHistory observation : observations) {
			observation.setSampleId(sample.getId());
			observation.setPatientId(patientId);
			observationDAO.insertData(observation);
		}
	}

	private void persistPatientData() {
		Patient existingPatient = null;

		if (patientMap.get(accessionNumber) != null) {
			patientUpdate.persistPatientData(patientMap.get(accessionNumber));
			patientId = patientUpdate.getPatientId(null);
		} else {
			if (isNewSample) {
				Patient patient = new Patient();
				PatientDAO patientDAO = new PatientDAOImpl();
				patient.setSysUserId(currentUserId);
				patient.setPerson(PatientUtil.getUnknownPerson());
				patientDAO.insertData(patient);
				patientId = patient.getId();
			} else {
				existingPatient = sampleHumanDAO.getPatientForSample(sample);
				patientId = existingPatient.getId();
			}			
		}
	}

	private void persistSampleData() {
		SampleItemDAO sampleItemDAO = new SampleItemDAOImpl();
		AnalysisDAO analysisDAO = new AnalysisDAOImpl();
		TestDAO testDAO = new TestDAOImpl();
		String analysisRevision = SystemConfiguration.getInstance().getAnalysisDefaultRevision();


		if (isNewSample) {
			sampleDAO.insertDataWithAccessionNumber(sample);
			buildSampleHuman();
			sampleHumanDAO.insertData(sampleHuman);
		} else {
			sampleDAO.updateData(sample);
			buildSampleHuman();
			sampleHumanDAO.updateData(sampleHuman);
		}


		if (!GenericValidator.isBlankOrNull(projectId)) {
			persistSampleProject();
		}

		for (SampleTestCollection sampleTestCollection : sampleItemsTests) {

			sampleTestCollection.item.setSample(sample);
			sampleItemDAO.insertData(sampleTestCollection.item);

			for (Test test : sampleTestCollection.tests) {
				testDAO.getData(test);

				Analysis analysis = populateAnalysis(analysisRevision,
                                                     sampleTestCollection,
                                                     test,
                                                     sampleTestCollection.testIdToUserSectionMap.get(test.getId()),
                                                     sampleTestCollection.testIdToUserSampleTypeMap.get(test.getId()));
				analysisDAO.insertData(analysis, false); // false--do not check for duplicates
			}

		}
	}

    private void buildSampleHuman(){
		sampleHuman = new SampleHuman();
		sampleHuman.setSampleId(sample.getId());
		if (!isNewSample) {
			sampleHumanDAO.getDataBySample(sampleHuman);
		}
		sampleHuman.setSysUserId(currentUserId);
		sampleHuman.setPatientId(patientId);
		sampleHuman.setProviderId(PatientUtil.getUnownProvider().getId());
    }

	private void persistRequesterData() {
		SampleRequesterDAO sampleRequesterDAO = new SampleRequesterDAOImpl();
		if (requesterSite != null) {
			requesterSite.setSampleId(Long.parseLong( sample.getId()));
			sampleRequesterDAO.insertData(requesterSite);
		}
	}

	private void persistSampleProject() throws LIMSRuntimeException {
		SampleProjectDAO sampleProjectDAO = new SampleProjectDAOImpl();
		ProjectDAO projectDAO = new ProjectDAOImpl();
		Project project = new Project();
		project.setId(projectId);
		projectDAO.getData(project);

		SampleProject sampleProject = new SampleProject();
		sampleProject.setProject(project);
		sampleProject.setSample(sample);
		sampleProject.setSysUserId(currentUserId);
		sampleProjectDAO.insertData(sampleProject);
	}

	private void persistInitialSampleConditions() {
		ObservationHistoryDAO ohDAO = new ObservationHistoryDAOImpl();

		for (SampleTestCollection sampleTestCollection : sampleItemsTests) {
			List<ObservationHistory> initialConditions = sampleTestCollection.initialSampleConditionIdList;

			if (initialConditions != null) {
				for (ObservationHistory observation : initialConditions) {
					observation.setSampleId(sampleTestCollection.item.getSample().getId());
					observation.setSampleItemId(sampleTestCollection.item.getId());
					observation.setPatientId(patientId);
					observation.setSysUserId(currentUserId);
					ohDAO.insertData(observation);
				}
			}
		}
	}

	private Analysis populateAnalysis(String analysisRevision, SampleTestCollection sampleTestCollection, Test test, String userSelectedTestSection, String sampleTypeName) {
	    java.sql.Date collectionDateTime = DateUtil.convertStringDateTimeToSqlDate(sampleTestCollection.collectionDate);
	    TestSection testSection = test.getTestSection();
		
		Panel panel = sampleAddService.getPanelForTest(test);
		
		Analysis analysis = new Analysis();
		analysis.setTest(test);
		analysis.setPanel(panel);
		analysis.setIsReportable(test.getIsReportable());
		analysis.setAnalysisType(DEFAULT_ANALYSIS_TYPE);
		analysis.setSampleItem(sampleTestCollection.item);
		analysis.setSysUserId(sampleTestCollection.item.getSysUserId());
		analysis.setRevision(analysisRevision);
		analysis.setStartedDate(collectionDateTime == null ? DateUtil.getNowAsSqlDate() : collectionDateTime );
		analysis.setStatusId(StatusService.getInstance().getStatusID(AnalysisStatus.NotStarted));
        if( !GenericValidator.isBlankOrNull( sampleTypeName )){
            analysis.setSampleTypeName( sampleTypeName );
        }
		analysis.setTestSection(testSection);
		return analysis;
	}

	@Override
	protected String getPageTitleKey() {
		return "sample.entry.title";
	}

	@Override
	protected String getPageSubtitleKey() {
		return "sample.entry.title";
	}
}
