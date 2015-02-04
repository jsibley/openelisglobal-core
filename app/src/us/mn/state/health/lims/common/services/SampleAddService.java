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
 * Copyright (C) ITECH, University of Washington, Seattle WA.  All Rights Reserved.
 *
 */
package us.mn.state.health.lims.common.services;

import org.apache.commons.validator.GenericValidator;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.DocumentHelper;
import org.dom4j.Element;

import us.mn.state.health.lims.common.formfields.FormFields;
import us.mn.state.health.lims.common.formfields.FormFields.Field;
import us.mn.state.health.lims.common.services.QAService.QAObservationType;
import us.mn.state.health.lims.common.services.QAService.QAObservationValueType;
import us.mn.state.health.lims.common.services.StatusService.SampleStatus;
import us.mn.state.health.lims.common.util.ConfigurationProperties;
import us.mn.state.health.lims.common.util.ConfigurationProperties.Property;
import us.mn.state.health.lims.common.util.DateUtil;
import us.mn.state.health.lims.note.valueholder.Note;
import us.mn.state.health.lims.observationhistory.valueholder.ObservationHistory;
import us.mn.state.health.lims.observationhistorytype.dao.ObservationHistoryTypeDAO;
import us.mn.state.health.lims.observationhistorytype.daoImpl.ObservationHistoryTypeDAOImpl;
import us.mn.state.health.lims.observationhistorytype.valueholder.ObservationHistoryType;
import us.mn.state.health.lims.panel.dao.PanelDAO;
import us.mn.state.health.lims.panel.daoimpl.PanelDAOImpl;
import us.mn.state.health.lims.panel.valueholder.Panel;
import us.mn.state.health.lims.panelitem.dao.PanelItemDAO;
import us.mn.state.health.lims.panelitem.daoimpl.PanelItemDAOImpl;
import us.mn.state.health.lims.panelitem.valueholder.PanelItem;
import us.mn.state.health.lims.qaevent.dao.QaEventDAO;
import us.mn.state.health.lims.qaevent.daoimpl.QaEventDAOImpl;
import us.mn.state.health.lims.qaevent.valueholder.QaEvent;
import us.mn.state.health.lims.sample.valueholder.Sample;
import us.mn.state.health.lims.sampleitem.valueholder.SampleItem;
import us.mn.state.health.lims.sampleqaevent.valueholder.SampleQaEvent;
import us.mn.state.health.lims.sourceofsample.dao.SourceOfSampleDAO;
import us.mn.state.health.lims.sourceofsample.daoimpl.SourceOfSampleDAOImpl;
import us.mn.state.health.lims.systemuser.dao.SystemUserDAO;
import us.mn.state.health.lims.systemuser.daoimpl.SystemUserDAOImpl;
import us.mn.state.health.lims.systemuser.valueholder.SystemUser;
import us.mn.state.health.lims.test.valueholder.Test;
import us.mn.state.health.lims.typeofsample.dao.TypeOfSampleDAO;
import us.mn.state.health.lims.typeofsample.daoimpl.TypeOfSampleDAOImpl;

import java.util.*;

public class SampleAddService {
	private final String xml;
	private final String currentUserId;
	private final Sample sample;
	private final List<SampleTestCollection> sampleItemsTests = new ArrayList<SampleTestCollection>();
	private final String receivedDate;
	private final Map<String, Panel> panelIdPanelMap = new HashMap<String, Panel>();
	private SystemUser systemUser;
	private boolean xmlProcessed = false;
	private int sampleItemIdIndex = 0;
	private static final boolean USE_INITIAL_SAMPLE_CONDITION = FormFields.getInstance().useField(Field.InitialSampleCondition);
	private static final boolean USE_RECEIVE_DATE_FOR_COLLECTION_DATE = !FormFields.getInstance().useField(Field.CollectionDate);
	private static final String INITIAL_CONDITION_OBSERVATION_ID;
	private static final TypeOfSampleDAO typeOfSampleDAO = new TypeOfSampleDAOImpl();
	private static final SourceOfSampleDAO sourceOfSampleDAO = new SourceOfSampleDAOImpl();
	private static final PanelDAO panelDAO = new PanelDAOImpl();
	private static final PanelItemDAO panelItemDAO = new PanelItemDAOImpl();
	
	static{
		ObservationHistoryTypeDAO ohtDAO = new ObservationHistoryTypeDAOImpl();

		INITIAL_CONDITION_OBSERVATION_ID = getObservationHistoryTypeId(ohtDAO, "initialSampleCondition");
	}

	private static String getObservationHistoryTypeId(ObservationHistoryTypeDAO ohtDAO, String name) {
		ObservationHistoryType oht;
		oht = ohtDAO.getByName(name);
		if (oht != null) {
			return oht.getId();
		}

		return null;
	}

	public SampleAddService(String xml, String currentUserId, Sample sample, String receiveDate) {
		this.xml = xml;
		this.currentUserId = currentUserId;
		this.sample = sample;
		this.receivedDate = receiveDate;
	}

	public List<SampleTestCollection> createSampleTestCollection() {
		xmlProcessed = true;
		String collectionDateFromRecieveDate = null;
		if (USE_RECEIVE_DATE_FOR_COLLECTION_DATE) {
			collectionDateFromRecieveDate = receivedDate + " 00:00:00";
		}
		
		try {
			Document sampleDom = DocumentHelper.parseText(xml);

			for (@SuppressWarnings("rawtypes")
			Iterator i = sampleDom.getRootElement().elementIterator("sample"); i.hasNext();) {
				sampleItemIdIndex++;

				Element sampleItem = (Element) i.next();

				String testIDs = sampleItem.attributeValue("tests");
				String panelIDs = sampleItem.attributeValue("panels");
				Map<String, String> testIdToUserSectionMap = getTestIdToSelectionMap(sampleItem.attributeValue("testSectionMap"));
                Map<String, String> testIdToSampleTypeMap = getTestIdToSelectionMap( sampleItem.attributeValue( "testSampleTypeMap" ) );
				
				String collectionDate = sampleItem.attributeValue("date").trim();
				String collectionTime = sampleItem.attributeValue("time").trim();
				String collectionDateTime = null;
				
				if (!GenericValidator.isBlankOrNull(collectionDate) && !GenericValidator.isBlankOrNull(collectionTime))
				    collectionDateTime = collectionDate + " " + collectionTime;
				else if (!GenericValidator.isBlankOrNull(collectionDate) && GenericValidator.isBlankOrNull(collectionTime))
				    collectionDateTime = collectionDate + " 00:00";

				augmentPanelIdToPanelMap(panelIDs);
				List<ObservationHistory> initialConditionList = null;

				if (USE_INITIAL_SAMPLE_CONDITION) {
					initialConditionList = addInitialSampleConditions(sampleItem, initialConditionList);
				}

				SampleItem item = new SampleItem();
				item.setSysUserId(currentUserId);
				item.setSample(sample);
				item.setTypeOfSample(typeOfSampleDAO.getTypeOfSampleById(sampleItem.attributeValue("sampleID")));
				if (ConfigurationProperties.getInstance().isPropertyValueEqual(Property.USE_SAMPLE_SOURCE, "true") &&
					!GenericValidator.isBlankOrNull(sampleItem.attributeValue("sourceID")))
					item.setSourceOfSample(sourceOfSampleDAO.getSourceOfSampleById(sampleItem.attributeValue("sourceID")));
				item.setSortOrder(Integer.toString(sampleItemIdIndex));
				item.setStatusId(StatusService.getInstance().getStatusID(SampleStatus.Entered));
				item.setCollector(sampleItem.attributeValue("collector"));
				
				List<QAService> rejectionList = null;
				if (!GenericValidator.isBlankOrNull(sampleItem.attributeValue("rejectionIds")) ||
					sampleItem.element("rejectionOther") != null) {
					rejectionList = addSampleRejectionEvents(item, sampleItem, rejectionList);
				}

				Note rejectOtherReason = null;
				if (sampleItem.element("rejectionOther") != null) {
					if (!GenericValidator.isBlankOrNull(sampleItem.element("rejectionOther").getText())) {
						rejectOtherReason = createRejectionNote(sampleItem.element("rejectionOther").getText(), rejectOtherReason);
					}
				}
				
				if (!GenericValidator.isBlankOrNull(collectionDateTime))
				    item.setCollectionDate(DateUtil.convertStringDateToTimestamp(collectionDateTime));
				List<Test> tests = new ArrayList<Test>();

				addTests(testIDs, tests);

				sampleItemsTests.add(new SampleTestCollection(item,	tests,
															  USE_RECEIVE_DATE_FOR_COLLECTION_DATE ? collectionDateFromRecieveDate : collectionDateTime, initialConditionList,
															  rejectionList, rejectOtherReason, testIdToUserSectionMap, testIdToSampleTypeMap));

			}
		} catch (DocumentException e) {
			e.printStackTrace();
		}
		
		return sampleItemsTests;
	}

	public Panel getPanelForTest(Test test) throws IllegalThreadStateException{
		if( !xmlProcessed){
			throw new IllegalThreadStateException("createSampleTestCollection must be called first");
		}	
		
		List<PanelItem> panelItems = panelItemDAO.getPanelItemByTestId( test.getId());
		
		for( PanelItem panelItem : panelItems){
			Panel panel = panelIdPanelMap.get(panelItem.getPanel().getId());
			if( panel != null){
				return panel;
			}
		}

		return null;
	}

	public void setInitialSampleItemOrderValue(int initialValue ){
		sampleItemIdIndex = initialValue;
	}
	
	private Map<String, String> getTestIdToSelectionMap(String mapPairs) {
		Map<String, String> sectionMap = new HashMap<String, String>();

		String[] maps = mapPairs.split(",");
		for (String map : maps) {
			String[] mapping = map.split(":");
			if (mapping.length == 2) {
				sectionMap.put(mapping[0].trim(), mapping[1].trim());
			}
		}

		return sectionMap;
	}

    private void augmentPanelIdToPanelMap(String panelIDs) {
		if(panelIDs != null){
			String[] ids = panelIDs.split(",");
			for( String id : ids){
				if( !GenericValidator.isBlankOrNull(id)){
					panelIdPanelMap.put(id, panelDAO.getPanelById(id));
				}
			}
		}
	}
	
	private List<ObservationHistory> addInitialSampleConditions(Element sampleItem, List<ObservationHistory> initialConditionList) {
		String initialSampleConditionIdString = sampleItem.attributeValue("initialConditionIds");
		if (!GenericValidator.isBlankOrNull(initialSampleConditionIdString)) {
			String[] initialSampleConditionIds = initialSampleConditionIdString.split(",");
			initialConditionList = new ArrayList<ObservationHistory>();

			for (int j = 0; j < initialSampleConditionIds.length; ++j) {
				ObservationHistory initialSampleConditions = new ObservationHistory();
				initialSampleConditions.setValue(initialSampleConditionIds[j]);
				initialSampleConditions.setValueType(ObservationHistory.ValueType.DICTIONARY);
				initialSampleConditions.setObservationHistoryTypeId(INITIAL_CONDITION_OBSERVATION_ID);
				initialConditionList.add(initialSampleConditions);
			}
		}
		// Handle 'Other Condition' option in modal version of sample entry
		if (sampleItem.element("initialConditionOther") != null) {
			String initialSampleConditionOtherString = sampleItem.element("initialConditionOther").getText();
			if (!GenericValidator.isBlankOrNull(initialSampleConditionOtherString)) {
				ObservationHistory initialSampleConditionOther = new ObservationHistory();
				initialSampleConditionOther.setValue(initialSampleConditionOtherString);
				initialSampleConditionOther.setValueType(ObservationHistory.ValueType.LITERAL);
				initialSampleConditionOther.setObservationHistoryTypeId(INITIAL_CONDITION_OBSERVATION_ID);
				initialConditionList.add(initialSampleConditionOther);
			}
		}
		return initialConditionList;
	}
	
	private void addTests(String testIDs, List<Test> tests) {
		StringTokenizer tokenizer = new StringTokenizer(testIDs, ",");

		while (tokenizer.hasMoreTokens()) {
			Test test = new Test();
			test.setId(tokenizer.nextToken().trim());
			tests.add(test);
		}
	}
	
    private List<QAService> addSampleRejectionEvents(SampleItem sampleItem, Element sampleElement, List<QAService> rejectionList) {
		String rejectionIdString = sampleElement.attributeValue("rejectionIds");
		String rejectionAuthorizer = sampleElement.element("rejectionTech") != null ? sampleElement.element("rejectionTech").getText() : "";
		rejectionList = new ArrayList<QAService>();
		if (!GenericValidator.isBlankOrNull(rejectionIdString)) {
			String[] rejectionIds = rejectionIdString.split(",");
			for (int j = 0; j < rejectionIds.length; ++j) {
				rejectionList.add(createRejectionQaService(rejectionIds[j], sampleItem, rejectionAuthorizer));
			}
		}
		// Handle 'Other Reason' option in modal version of sample entry
		if (sampleElement.element("rejectionOther") != null) {
			String rejectionOther = sampleElement.element("rejectionOther").getText();
			if (!GenericValidator.isBlankOrNull(rejectionOther)) {
				rejectionList.add(createRejectionQaService(retrieveQaEventIdForName("Other"), sampleItem, rejectionAuthorizer));
			}
		}

		return rejectionList.isEmpty() ? null : rejectionList;
	}

    private String retrieveQaEventIdForName(String name) {
		QaEvent qaEvent = new QaEvent();
		QaEventDAO qaEventDAO = new QaEventDAOImpl();
		qaEvent.setQaEventName(name);
		qaEvent = qaEventDAO.getQaEventByName(qaEvent);
		return qaEvent.getId();    	
    }
    
    private QAService createRejectionQaService(String id, SampleItem item, String authorizer) {
		QAService qaService = new QAService(new SampleQaEvent());
		qaService.setCurrentUserId(currentUserId);
		qaService.setReportTime(receivedDate);
		qaService.setQaEventById(id);
		qaService.setSampleItem(item);
		qaService.setObservation(QAObservationType.SECTION, "Reception", QAObservationValueType.LITERAL, true);
		qaService.setObservation(QAObservationType.AUTHORIZER, authorizer, QAObservationValueType.LITERAL, false);
		return qaService;    	
    }

	private Note createRejectionNote(String noteText, Note note) {
		systemUser = new SystemUser();
		systemUser.setId(currentUserId);
		SystemUserDAO systemUserDAO = new SystemUserDAOImpl();
		systemUserDAO.getData(systemUser);

		note = new Note();
		note.setText(noteText);
		note.setSysUserId(currentUserId);
		note.setNoteType(Note.REJECT_REASON);
		note.setSubject("QaEvent Note");
		note.setSystemUser(systemUser);
		note.setSystemUserId(currentUserId);
		note.setReferenceTableId(QAService.TABLE_REFERENCE_ID);

		return note;
	}

	public final class SampleTestCollection {
		public SampleItem item;
		public List<Test> tests;
		public String collectionDate;
		public List<ObservationHistory> initialSampleConditionIdList;
		public List<QAService> rejections;
		public Note rejectionOtherReason;
		public Map<String,String> testIdToUserSectionMap;
        public Map<String,String> testIdToUserSampleTypeMap;

		public SampleTestCollection(SampleItem item, List<Test> tests, String collectionDate, List<ObservationHistory> initialConditionList,
									List<QAService> rejectionList, Note rejectOtherReason, Map<String,String> testIdToUserSectionMap,
									Map<String,String> testIdToUserSampleTypeMap) {
			this.item = item;
			this.tests = tests;
			this.collectionDate = collectionDate;
			this.testIdToUserSectionMap = testIdToUserSectionMap;
            this.testIdToUserSampleTypeMap = testIdToUserSampleTypeMap;
			initialSampleConditionIdList = initialConditionList;
			rejections = rejectionList;
			rejectionOtherReason = rejectOtherReason;
		}
	}
}
