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

import org.apache.commons.validator.GenericValidator;
import org.apache.struts.Globals;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.action.ActionMessages;
import org.hibernate.StaleObjectStateException;
import org.hibernate.Transaction;

import us.mn.state.health.lims.address.dao.OrganizationAddressDAO;
import us.mn.state.health.lims.address.daoimpl.OrganizationAddressDAOImpl;
import us.mn.state.health.lims.address.valueholder.OrganizationAddress;
import us.mn.state.health.lims.analysis.dao.AnalysisDAO;
import us.mn.state.health.lims.analysis.daoimpl.AnalysisDAOImpl;
import us.mn.state.health.lims.analysis.valueholder.Analysis;
import us.mn.state.health.lims.common.action.BaseAction;
import us.mn.state.health.lims.common.action.BaseActionForm;
import us.mn.state.health.lims.common.exception.LIMSRuntimeException;
import us.mn.state.health.lims.common.formfields.FormFields;
import us.mn.state.health.lims.common.formfields.FormFields.Field;
import us.mn.state.health.lims.common.services.QAService;
import us.mn.state.health.lims.common.services.SampleAddService.SampleTestCollection;
import us.mn.state.health.lims.common.services.StatusService;
import us.mn.state.health.lims.common.services.StatusService.AnalysisStatus;
import us.mn.state.health.lims.common.services.TableIdService;
import us.mn.state.health.lims.common.util.ConfigurationProperties;
import us.mn.state.health.lims.common.util.ConfigurationProperties.Property;
import us.mn.state.health.lims.common.util.DateUtil;
import us.mn.state.health.lims.common.util.SystemConfiguration;
import us.mn.state.health.lims.common.util.validator.ActionError;
import us.mn.state.health.lims.dataexchange.order.dao.ElectronicOrderDAO;
import us.mn.state.health.lims.dataexchange.order.daoimpl.ElectronicOrderDAOImpl;
import us.mn.state.health.lims.hibernate.HibernateUtil;
import us.mn.state.health.lims.note.dao.NoteDAO;
import us.mn.state.health.lims.note.daoimpl.NoteDAOImpl;
import us.mn.state.health.lims.observationhistory.dao.ObservationHistoryDAO;
import us.mn.state.health.lims.observationhistory.daoimpl.ObservationHistoryDAOImpl;
import us.mn.state.health.lims.observationhistory.valueholder.ObservationHistory;
import us.mn.state.health.lims.organization.dao.OrganizationDAO;
import us.mn.state.health.lims.organization.dao.OrganizationOrganizationTypeDAO;
import us.mn.state.health.lims.organization.daoimpl.OrganizationDAOImpl;
import us.mn.state.health.lims.organization.daoimpl.OrganizationOrganizationTypeDAOImpl;
import us.mn.state.health.lims.organization.valueholder.Organization;
import us.mn.state.health.lims.panel.valueholder.Panel;
import us.mn.state.health.lims.patient.action.IPatientUpdate;
import us.mn.state.health.lims.patient.action.PatientManagementUpdateAction;
import us.mn.state.health.lims.patient.action.PatientManagementUpdateAction.PatientUpdateStatus;
import us.mn.state.health.lims.patient.action.bean.PatientManagementInfo;
import us.mn.state.health.lims.patient.valueholder.Patient;
import us.mn.state.health.lims.person.dao.PersonDAO;
import us.mn.state.health.lims.person.daoimpl.PersonDAOImpl;
import us.mn.state.health.lims.project.dao.ProjectDAO;
import us.mn.state.health.lims.project.daoimpl.ProjectDAOImpl;
import us.mn.state.health.lims.project.valueholder.Project;
import us.mn.state.health.lims.provider.dao.ProviderDAO;
import us.mn.state.health.lims.provider.daoimpl.ProviderDAOImpl;
import us.mn.state.health.lims.qaevent.dao.QaEventDAO;
import us.mn.state.health.lims.qaevent.dao.QaObservationDAO;
import us.mn.state.health.lims.qaevent.daoimpl.QaEventDAOImpl;
import us.mn.state.health.lims.qaevent.daoimpl.QaObservationDAOImpl;
import us.mn.state.health.lims.qaevent.valueholder.QaEvent;
import us.mn.state.health.lims.qaevent.valueholder.QaObservation;
import us.mn.state.health.lims.requester.dao.SampleRequesterDAO;
import us.mn.state.health.lims.requester.daoimpl.SampleRequesterDAOImpl;
import us.mn.state.health.lims.requester.valueholder.SampleRequester;
import us.mn.state.health.lims.sample.action.util.SamplePatientUpdateData;
import us.mn.state.health.lims.sample.bean.SampleOrderItem;
import us.mn.state.health.lims.sample.dao.SampleDAO;
import us.mn.state.health.lims.sample.daoimpl.SampleDAOImpl;
import us.mn.state.health.lims.samplehuman.dao.SampleHumanDAO;
import us.mn.state.health.lims.samplehuman.daoimpl.SampleHumanDAOImpl;
import us.mn.state.health.lims.sampleitem.dao.SampleItemDAO;
import us.mn.state.health.lims.sampleitem.daoimpl.SampleItemDAOImpl;
import us.mn.state.health.lims.sampleproject.dao.SampleProjectDAO;
import us.mn.state.health.lims.sampleproject.daoimpl.SampleProjectDAOImpl;
import us.mn.state.health.lims.sampleproject.valueholder.SampleProject;
import us.mn.state.health.lims.sampleqaevent.dao.SampleQaEventDAO;
import us.mn.state.health.lims.sampleqaevent.daoimpl.SampleQaEventDAOImpl;
import us.mn.state.health.lims.sampleqaevent.valueholder.SampleQaEvent;
import us.mn.state.health.lims.test.dao.TestDAO;
import us.mn.state.health.lims.test.dao.TestSectionDAO;
import us.mn.state.health.lims.test.daoimpl.TestDAOImpl;
import us.mn.state.health.lims.test.daoimpl.TestSectionDAOImpl;
import us.mn.state.health.lims.test.valueholder.Test;
import us.mn.state.health.lims.test.valueholder.TestSection;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.lang.reflect.InvocationTargetException;
import java.util.List;

public class SamplePatientEntrySaveAction extends BaseAction {

	private static final String DEFAULT_ANALYSIS_TYPE = "MANUAL";


	private OrganizationDAO orgDAO = new OrganizationDAOImpl();
	private OrganizationAddressDAO orgAddressDAO = new OrganizationAddressDAOImpl();
	private OrganizationOrganizationTypeDAO orgOrgTypeDAO = new OrganizationOrganizationTypeDAOImpl();
	private TestSectionDAO testSectionDAO = new TestSectionDAOImpl();
	private ElectronicOrderDAO electronicOrderDAO = new ElectronicOrderDAOImpl();

	@Override
	protected ActionForward performAction(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response)
			throws Exception {

		String forward = FWD_SUCCESS;

        SamplePatientUpdateData updateData = new SamplePatientUpdateData( getSysUserId(request)) ;

		boolean useInitialSampleCondition = FormFields.getInstance().useField(Field.InitialSampleCondition);
		BaseActionForm dynaForm = (BaseActionForm) form;
		PatientManagementInfo patientInfo = (PatientManagementInfo ) dynaForm.get("patientProperties");
        SampleOrderItem sampleOrder = (SampleOrderItem)dynaForm.get("sampleOrderItems");

        ActionMessages errors = new ActionMessages();

        boolean trackPayments = ConfigurationProperties.getInstance().isPropertyValueEqual(Property.TRACK_PATIENT_PAYMENT, "true");
        if (FormFields.getInstance().useField(Field.SAMPLE_ENTRY_MODAL_VERSION) &&
            FormFields.getInstance().useField(Field.SAMPLE_ENTRY_REJECTION_IN_MODAL_VERSION))
        	updateData.setSampleRejection(true);

		String receivedDateForDisplay =  sampleOrder.getReceivedDateForDisplay();

		if (!GenericValidator.isBlankOrNull(sampleOrder.getReceivedTime())) {
			receivedDateForDisplay += " " + sampleOrder.getReceivedTime();
		}else{
			receivedDateForDisplay += " 00:00";
		}

        updateData.setCollectionDateFromRecieveDateIfNeeded( receivedDateForDisplay );
        updateData.initializeRequester( sampleOrder );
        updateData.setProjectIds(sampleOrder);

		IPatientUpdate patientUpdate = new PatientManagementUpdateAction();
		testAndInitializePatientForSaving(mapping, request, patientInfo, patientUpdate, updateData);

        updateData.setAccessionNumber( sampleOrder.getLabNo() );
		updateData.initProvider( sampleOrder );
		updateData.initSampleData( dynaForm.getString( "sampleXML" ), receivedDateForDisplay, trackPayments, sampleOrder );
		if (patientUpdate.getPatientUpdateStatus() == PatientUpdateStatus.ADD && !updateData.isNewSample())
			updatePatientInfo(patientInfo, patientUpdate, updateData, mapping, request);
		updateData.validateSample( errors );

		if (errors.size() > 0) {
			// we need to clear sampleOrderItems.labNo, else the field will not show up in the sampleOrder.jsp tile
			// (probably a side-effect of not wanting the labNo field displayed on the sample edit page)
			sampleOrder.setLabNo("");
			saveErrors(request, errors);
			request.setAttribute(Globals.ERROR_KEY, errors);
			return mapping.findForward(FWD_FAIL);
		}

		Transaction tx = HibernateUtil.getSession().beginTransaction();

		try {
			persistOrganizationData(updateData);
			
			if ( updateData.isSavePatient()) {
				patientUpdate.persistPatientData(patientInfo);
			}

            updateData.setPatientId( patientUpdate.getPatientId(dynaForm) );

			persistProviderData( updateData );
			persistSampleData(updateData);
			persistRequesterData(updateData);
			if (useInitialSampleCondition) {
				persistInitialSampleConditions(updateData);
			}

			if (updateData.getSampleRejection())
				persistSampleRejectionData(updateData);

			persistObservations(updateData);

			tx.commit();

		} catch (LIMSRuntimeException lre) {
			tx.rollback();

			ActionError error;
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

    private void persistObservations(SamplePatientUpdateData updateData) {

        ObservationHistoryDAO observationDAO = new ObservationHistoryDAOImpl();
		for (ObservationHistory observation : updateData.getObservations()) {
			observation.setSampleId(updateData.getSample().getId());
			observation.setPatientId(updateData.getPatientId());
			observationDAO.insertData( observation );
		}
	}

	private void testAndInitializePatientForSaving( ActionMapping mapping, HttpServletRequest request, PatientManagementInfo patientInfo,
                                                    IPatientUpdate patientUpdate, SamplePatientUpdateData updateData ) throws IllegalAccessException, InvocationTargetException, NoSuchMethodException {

		patientUpdate.setPatientUpdateStatus(patientInfo);
		updateData.setSavePatient(  patientUpdate.getPatientUpdateStatus() != PatientManagementUpdateAction.PatientUpdateStatus.NO_ACTION );

		if (updateData.isSavePatient()) {
           updateData.setPatientErrors( patientUpdate.preparePatientData(mapping, request, patientInfo) );
		} else {
            updateData.setPatientErrors(new ActionMessages());
		}
	}

	private void persistOrganizationData( SamplePatientUpdateData updateData ) {
        Organization newOrganization = updateData.getNewOrganization();
		if (newOrganization != null) {
			orgDAO.insertData(newOrganization);
			orgOrgTypeDAO.linkOrganizationAndType(newOrganization, TableIdService.REFERRING_ORG_TYPE_ID);
			if (updateData.getRequesterSite() != null) {
                updateData.getRequesterSite().setRequesterId( newOrganization.getId() );
			}

			for (OrganizationAddress address : updateData.getOrgAddressExtra()) {
				address.setOrganizationId(newOrganization.getId());
				orgAddressDAO.insert(address);
			}
		}
		
		if( updateData.getCurrentOrganization() != null){
			orgDAO.updateData(updateData.getCurrentOrganization());
		}

	}

	private void persistProviderData( SamplePatientUpdateData updateData ) {
		if (updateData.getProviderPerson() != null && updateData.getProvider()!= null) {
			PersonDAO personDAO = new PersonDAOImpl();
			ProviderDAO providerDAO = new ProviderDAOImpl();

			personDAO.insertData(updateData.getProviderPerson());
            updateData.getProvider().setPerson( updateData.getProviderPerson() );

    		if (updateData.isNewSample())
    			providerDAO.insertData(updateData.getProvider());
    		else
    			providerDAO.updateData(updateData.getProvider());
		}
	}

	private void persistSampleData( SamplePatientUpdateData updateData ) {
		SampleDAO sampleDAO = new SampleDAOImpl();
		SampleHumanDAO sampleHumanDAO = new SampleHumanDAOImpl();
		SampleItemDAO sampleItemDAO = new SampleItemDAOImpl();
		AnalysisDAO analysisDAO = new AnalysisDAOImpl();
		TestDAO testDAO = new TestDAOImpl();
		String analysisRevision = SystemConfiguration.getInstance().getAnalysisDefaultRevision();

		if (updateData.isNewSample())
			sampleDAO.insertDataWithAccessionNumber(updateData.getSample());
		else
			sampleDAO.updateData(updateData.getSample());

		if (!GenericValidator.isBlankOrNull(updateData.getProjectId())) {
			persistSampleProject(updateData.getProjectId(), updateData);
		}
		if (!GenericValidator.isBlankOrNull(updateData.getProject2Id())) {
			persistSampleProject(updateData.getProject2Id(), updateData);
		}

		for (SampleTestCollection sampleTestCollection : updateData.getSampleItemsTests()) {

			sampleItemDAO.insertData(sampleTestCollection.item);

			for (Test test : sampleTestCollection.tests) {
				testDAO.getData(test);

				Analysis analysis = populateAnalysis(analysisRevision,
                                                     sampleTestCollection,
                                                     test,
                                                     sampleTestCollection.testIdToUserSectionMap.get(test.getId()),
                                                     sampleTestCollection.testIdToUserSampleTypeMap.get(test.getId()),
                                                     updateData);
				analysisDAO.insertData(analysis, false); // false--do not check for duplicates
			}

		}

        updateData.buildSampleHuman();

		if (updateData.isNewSample())
			sampleHumanDAO.insertData(updateData.getSampleHuman());
		else
			sampleHumanDAO.updateData(updateData.getSampleHuman());

		if(updateData.getElectronicOrder() != null){
			electronicOrderDAO.updateData(updateData.getElectronicOrder());
		}
	}

	private void persistSampleProject(String projectId, SamplePatientUpdateData updateData) throws LIMSRuntimeException {
		SampleProjectDAO sampleProjectDAO = new SampleProjectDAOImpl();
		ProjectDAO projectDAO = new ProjectDAOImpl();
		Project project = new Project();
		project.setId(projectId);
		projectDAO.getData(project);

		SampleProject sampleProject = new SampleProject();
		sampleProject.setProject(project);
		sampleProject.setSample(updateData.getSample());
		sampleProject.setSysUserId(currentUserId);
		sampleProjectDAO.insertData(sampleProject);
	}

	private void persistRequesterData( SamplePatientUpdateData updateData ) {
		SampleRequesterDAO sampleRequesterDAO = new SampleRequesterDAOImpl();
		if (updateData.getProviderPerson() != null && !GenericValidator.isBlankOrNull(updateData.getProviderPerson().getId())) {
			SampleRequester sampleRequester = new SampleRequester();
			sampleRequester.setRequesterId(updateData.getProviderPerson().getId());
			sampleRequester.setRequesterTypeId(TableIdService.PROVIDER_REQUESTER_TYPE_ID);
			sampleRequester.setSampleId(Long.parseLong( updateData.getSample().getId()));
			sampleRequester.setSysUserId(updateData.getCurrentUserId());
			sampleRequesterDAO.insertData(sampleRequester);
		}

		if (updateData.getRequesterSite() != null) {
            updateData.getRequesterSite().setSampleId( Long.parseLong( updateData.getSample().getId() ) );
			if( updateData.getNewOrganization() != null){
                updateData.getRequesterSite().setRequesterId( updateData.getNewOrganization().getId() );
			}
			sampleRequesterDAO.insertData(updateData.getRequesterSite());
		}
	}

	private void persistInitialSampleConditions( SamplePatientUpdateData updateData ) {
		ObservationHistoryDAO ohDAO = new ObservationHistoryDAOImpl();

		for (SampleTestCollection sampleTestCollection : updateData.getSampleItemsTests()) {
			List<ObservationHistory> initialConditions = sampleTestCollection.initialSampleConditionIdList;

			if (initialConditions != null) {
				for (ObservationHistory observation : initialConditions) {
					observation.setSampleId(sampleTestCollection.item.getSample().getId());
					observation.setSampleItemId(sampleTestCollection.item.getId());
					observation.setPatientId(updateData.getPatientId());
					observation.setSysUserId( updateData.getCurrentUserId());
					ohDAO.insertData(observation);
				}
			}
		}
	}

	private Analysis populateAnalysis( String analysisRevision, SampleTestCollection sampleTestCollection, Test test, String userSelectedTestSection, String sampleTypeName, SamplePatientUpdateData updateData ) {
	    java.sql.Date collectionDateTime = DateUtil.convertStringDateTimeToSqlDate(sampleTestCollection.collectionDate);
	    TestSection testSection = test.getTestSection();
		if( !GenericValidator.isBlankOrNull(userSelectedTestSection)){
			testSection = testSectionDAO.getTestSectionById( userSelectedTestSection);
		}
		
		Panel panel = updateData.getSampleAddService().getPanelForTest( test );
		
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

	private void updatePatientInfo(PatientManagementInfo patientInfo, IPatientUpdate patientUpdate, SamplePatientUpdateData updateData,
			ActionMapping mapping, HttpServletRequest request) throws IllegalAccessException, InvocationTargetException, NoSuchMethodException {
		SampleHumanDAO sampleHumanDAO = new SampleHumanDAOImpl();
		Patient existingPatient = sampleHumanDAO.getPatientForSample(updateData.getSample());
		updateData.setPatientId(existingPatient.getId());
		patientInfo.setPatientPK(existingPatient.getId());
		patientInfo.setPatientProcessingStatus("update");
		patientUpdate.setPatientUpdateStatus(patientInfo);
	    updateData.setPatientErrors( patientUpdate.preparePatientData(mapping, request, patientInfo) );
	}

	private void persistSampleRejectionData(SamplePatientUpdateData updateData) {
		SampleQaEventDAO sampleQaEventDAO = new SampleQaEventDAOImpl();
		QaObservationDAO qaObservationDAO = new QaObservationDAOImpl();
		NoteDAO noteDAO = new NoteDAOImpl();

		QaEvent qaEvent = new QaEvent();
		QaEventDAO qaEventDAO = new QaEventDAOImpl();
		qaEvent.setQaEventName("Other");
		qaEvent = qaEventDAO.getQaEventByName(qaEvent);
		String otherId = qaEvent.getId();

		for (SampleTestCollection stc : updateData.getSampleItemsTests()) {
			if (stc.rejections != null && !stc.rejections.isEmpty()) {
				for (QAService qaService : stc.rejections) {
					SampleQaEvent event = qaService.getSampleQaEvent();
					event.setSample(updateData.getSample());
					sampleQaEventDAO.insertData(event);

					/* persist "Section" and "Authorizer" QaObservations for the SampleQaEvent */
					for (QaObservation observation : qaService.getUpdatedObservations()) {
						observation.setObservedId(event.getId());
						qaObservationDAO.insertData(observation);
					}
					
					/* persist "Other Reason" note, if present */
					if (!GenericValidator.isBlankOrNull(otherId) &&
						otherId.equals(qaService.getQAEvent().getId()) &&
						stc.rejectionOtherReason != null) {
						stc.rejectionOtherReason.setReferenceId(event.getId());
						noteDAO.insertData(stc.rejectionOtherReason);
					}			 
				}
			}
		}
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
