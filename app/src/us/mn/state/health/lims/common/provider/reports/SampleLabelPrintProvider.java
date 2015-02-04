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
package us.mn.state.health.lims.common.provider.reports;

import java.io.IOException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Map.Entry;

import javax.print.Doc;
import javax.print.DocFlavor;
import javax.print.DocPrintJob;
import javax.print.PrintException;
import javax.print.PrintService;
import javax.print.PrintServiceLookup;
import javax.print.SimpleDoc;
import javax.print.attribute.HashPrintRequestAttributeSet;
import javax.print.attribute.PrintRequestAttributeSet;
import javax.print.attribute.standard.Copies;
import javax.print.attribute.standard.PrinterName;
import javax.print.event.PrintJobEvent;
import javax.print.event.PrintJobListener;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.validator.GenericValidator;
import org.hibernate.Transaction;

import us.mn.state.health.lims.analysis.dao.AnalysisDAO;
import us.mn.state.health.lims.analysis.daoimpl.AnalysisDAOImpl;
import us.mn.state.health.lims.analysis.valueholder.Analysis;
import us.mn.state.health.lims.common.exception.LIMSInvalidPrinterException;
import us.mn.state.health.lims.common.exception.LIMSPrintException;
import us.mn.state.health.lims.common.log.LogEvent;
import us.mn.state.health.lims.common.services.IPatientService;
import us.mn.state.health.lims.common.services.PatientService;
import us.mn.state.health.lims.common.services.StatusService;
import us.mn.state.health.lims.common.services.StatusService.AnalysisStatus;
import us.mn.state.health.lims.common.services.StatusService.SampleStatus;
import us.mn.state.health.lims.common.servlet.validation.AjaxServlet;
import us.mn.state.health.lims.common.util.ConfigurationProperties;
import us.mn.state.health.lims.common.util.DateUtil;
import us.mn.state.health.lims.common.util.StringUtil;
import us.mn.state.health.lims.common.util.SystemConfiguration;
import us.mn.state.health.lims.common.util.ConfigurationProperties.Property;
import us.mn.state.health.lims.hibernate.HibernateUtil;
import us.mn.state.health.lims.login.valueholder.UserSessionData;
import us.mn.state.health.lims.patient.dao.PatientDAO;
import us.mn.state.health.lims.patient.daoimpl.PatientDAOImpl;
import us.mn.state.health.lims.patient.util.PatientUtil;
import us.mn.state.health.lims.patient.valueholder.Patient;
import us.mn.state.health.lims.sample.dao.SampleDAO;
import us.mn.state.health.lims.sample.daoimpl.SampleDAOImpl;
import us.mn.state.health.lims.sample.util.AccessionNumberUtil;
import us.mn.state.health.lims.sample.valueholder.Sample;
import us.mn.state.health.lims.samplehuman.dao.SampleHumanDAO;
import us.mn.state.health.lims.samplehuman.daoimpl.SampleHumanDAOImpl;
import us.mn.state.health.lims.samplehuman.valueholder.SampleHuman;
import us.mn.state.health.lims.sampleitem.dao.SampleItemDAO;
import us.mn.state.health.lims.sampleitem.daoimpl.SampleItemDAOImpl;
import us.mn.state.health.lims.sampleitem.valueholder.SampleItem;
import us.mn.state.health.lims.typeofsample.dao.TypeOfSampleDAO;
import us.mn.state.health.lims.typeofsample.daoimpl.TypeOfSampleDAOImpl;
import us.mn.state.health.lims.typeofsample.valueholder.TypeOfSample;

/**
 * @author benzd1
 * modified for bugzilla 2380
 */
public class SampleLabelPrintProvider extends BasePrintProvider {

	private Map<String, String> labelData = new HashMap<String, String>();
	private Map<Property, Property> propList = new HashMap<Property, Property>();
	private List<Property> masterPrintOrder = new ArrayList<Property>();
	private List<Property> itemPrintOrder = new ArrayList<Property>();
	private PrintService ps = null;
	private int masterCount = 0;
	private int itemCount = 0;
	private String accessionNumber = null;
	private Sample sample = null;
	private Patient patient = null;
	private IPatientService patientService = null;
	private List<String> existingSampleItemTypes = null;
	private List<String> existingSampleItemSections = null;
	private String returnedData = null;

	public SampleLabelPrintProvider() {
		super();
	}

	public SampleLabelPrintProvider(AjaxServlet ajaxServlet) {
		this.ajaxServlet = ajaxServlet;
	}

	public void processRequest(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException, PrintException, LIMSPrintException, LIMSInvalidPrinterException {

		UserSessionData usd = (UserSessionData)request.getSession().getAttribute(USER_SESSION_DATA);
		String accessionCount = (String) request.getParameter("accessionCount");
		String accessionStart = (String) request.getParameter("labelAccessionNumber");
		String accessionEnd = (String) request.getParameter("labelAccessionNumber2");
		String printerName = (String) request.getParameter("printerName");
		String masterLabels = (String) request.getParameter("masterLabels");
		String itemLabels = (String) request.getParameter("itemLabels");
		String result = printLabels(request, usd, accessionCount, accessionStart, accessionEnd, printerName, masterLabels, itemLabels);
		ajaxServlet.sendData("result", result, request, response);
	}

	/**
	 * printLabels() - for SampleLabelPrintProvider
	 * 
	 * @param usd				- UserSessionData from request
	 * 		  accessionCount	- String of how many accession numbers to generate/print
	 *        accessionStart	- String of starting accession number range to print
	 *        accessionEnd		- String of ending accession number range to print
	 * 		  printerName		- String of name of printer to use
	 * 		  masterLabels		- String of number of master labels to print
	 *        itemLabels		- String of number of item labels to print
	 * @return String - success or fail
	 */
	public String printLabels(HttpServletRequest request, UserSessionData usd, String accessionCount, String accessionStart, String accessionEnd,
							  String printerName, String masterLabels, String itemLabels) {
		returnedData = validateInput(accessionCount, accessionStart, accessionEnd, printerName, masterLabels, itemLabels);
		if (!FWD_SUCCESS.equals(returnedData))
			return returnedData;
		
		initializeLabelProperties();
		String[] accList = generateAccessionList(accessionCount, accessionStart, accessionEnd);

		//bgm added to see if this will fix the error for a record lock when this Sample is added here and
		// then updated later,within same thread, on another screen.... like in QuickEntry.
		Transaction tx = HibernateUtil.getSession().beginTransaction();

		try {
			for (int i = 0; i < accList.length; i++) {
				accessionNumber = accList[i];
				initializeLabelData();
				populateSampleData(usd);
				populatePatientData();
				updateLabelSampleData();
				if (patientService != null)
					updateLabelPatientData();
				runPrintJobs();
			}
			tx.commit();
		} catch (NumberFormatException nfe) {
			tx.rollback();
			LogEvent.logError("SampleLabelPrintProvider","printLabels()", StringUtil.getMessageForKey("errors.labelprint.bad.number") + " : " + nfe.toString());
			returnedData = FWD_FAIL;
		} catch (Exception e) {
			tx.rollback();
			e.printStackTrace();
			LogEvent.logError("SampleLabelPrintProvider","printLabels()", e.toString());
			returnedData = FWD_FAIL;
		} finally {
			HibernateUtil.closeSession();
		}
		return returnedData;
	}

	private void populateSampleData(UserSessionData usd) {
		Set<Integer> excludedAnalysisStatusList = new HashSet<Integer>();
		Set<Integer> includedSampleStatusList = new HashSet<Integer>();
		excludedAnalysisStatusList.add(Integer.parseInt(StatusService.getInstance().getStatusID(AnalysisStatus.ReferredIn)));
		excludedAnalysisStatusList.add(Integer.parseInt(StatusService.getInstance().getStatusID(AnalysisStatus.Canceled)));
		includedSampleStatusList.add(Integer.parseInt(StatusService.getInstance().getStatusID(SampleStatus.Entered)));

		SampleDAO sampleDAO = new SampleDAOImpl();
		sample = sampleDAO.getSampleByAccessionNumber(accessionNumber);
		if (sample == null || GenericValidator.isBlankOrNull(sample.getId())) {
			sample = new Sample();
			Date today = Calendar.getInstance().getTime();
			String dateAsText = DateUtil.formatDateAsText(today);
			dateAsText += " " + Calendar.getInstance().get(Calendar.HOUR_OF_DAY) + ":" + Calendar.getInstance().get(Calendar.MINUTE);

			//1926 get sysUserId from login module
			String sysUserId = String.valueOf(usd.getSystemUserId());

			// insert sample
			sample.setSysUserId(sysUserId);
			sample.setAccessionNumber(accessionNumber);
			sample.setEnteredDate(DateUtil.getNowAsSqlDate());
			sample.setReceivedTimestamp(DateUtil.convertStringDateToTimestamp(dateAsText));
			sample.setDomain(SystemConfiguration.getInstance().getHumanDomain());
			sampleDAO.insertDataWithAccessionNumber(sample);

			// insert patient
			patient = new Patient();
			PatientDAO patientDAO = new PatientDAOImpl();
			patient.setSysUserId(sysUserId);
			patient.setPerson(PatientUtil.getUnknownPerson());
			patientDAO.insertData(patient);

			// insert samplehuman
			SampleHuman sampleHuman = new SampleHuman();
			SampleHumanDAO sampleHumanDAO = new SampleHumanDAOImpl();
			sampleHuman.setSysUserId(sysUserId);
			sampleHuman.setSampleId(sample.getId());
			sampleHuman.setPatientId(patient.getId());
			sampleHuman.setProviderId(PatientUtil.getUnownProvider().getId());
			sampleHumanDAO.insertData(sampleHuman);
		} else {
			SampleItemDAO sampleItemDAO = new SampleItemDAOImpl();
			existingSampleItemTypes = new ArrayList<String>();
			existingSampleItemSections = new ArrayList<String>();
			List<SampleItem> sampleItemList = sampleItemDAO.getSampleItemsBySampleIdAndStatus(sample.getId(), includedSampleStatusList);
			for ( SampleItem sampItem: sampleItemList) {
				TypeOfSampleDAO typeOfSampleDAO = new TypeOfSampleDAOImpl();
				TypeOfSample typeOfSample = new TypeOfSample();
				typeOfSample.setId(sampItem.getTypeOfSampleId());
				typeOfSampleDAO.getData(typeOfSample);
				existingSampleItemTypes.add(typeOfSample.getLocalizedName());

				AnalysisDAO analysisDAO = new AnalysisDAOImpl();
				List<Analysis> analysisList = analysisDAO.getAnalysesBySampleItemsExcludingByStatusIds(sampItem, excludedAnalysisStatusList);
				String testSections = "";
				for (Analysis analysis: analysisList) {
					if (testSections.isEmpty()) testSections += ", ";
					if (analysis.getTestSectionName() != null && !analysis.getTestSectionName().isEmpty()) {
						testSections += analysis.getTestSectionName();
					}
				}
				existingSampleItemSections.add(testSections);
			}
		}
	}

	private void populatePatientData() {
		patient = new SampleHumanDAOImpl().getPatientForSample(sample);
		if (patient != null && !GenericValidator.isBlankOrNull(patient.getId())) {
			patientService = new PatientService(patient);
		}
	}

	private String validateInput(String accessionCount, String accessionStart, String accessionEnd, String printerName,
								 String masterLabels, String itemLabels) {
		if ((StringUtil.isNullorNill(accessionCount) && StringUtil.isNullorNill(accessionStart) && StringUtil.isNullorNill(accessionEnd)) ||
			StringUtil.isNullorNill(printerName) || StringUtil.isNullorNill(masterLabels) || "0".equals(masterLabels))
			return FWD_FAIL;

		masterCount = Integer.parseInt(masterLabels);
		itemCount = StringUtil.isNullorNill(itemLabels) ? 0 : Integer.parseInt(itemLabels);

		//bugzilla 2374 limit number of labels
		int maxNumberOfLabels = Integer.parseInt(SystemConfiguration.getInstance().getMaxNumberOfLabels());
		if (masterCount > maxNumberOfLabels || itemCount > maxNumberOfLabels) {
			LogEvent.logError("SampleLabelPrintProvider", "printLabels()", StringUtil.getMessageForKey("errors.labelprint.exceeded.maxnumber",
				SystemConfiguration.getInstance().getMaxNumberOfLabels()));
			return FWD_FAIL_MAX_LABELS_EXCEED;
		}
		
		//validate printer
		PrintService[] services = PrintServiceLookup.lookupPrintServices(null, null);
		String printer = null;
		PrinterName printerToUse = new PrinterName(printerName, null);

		for (int i = 0; i < services.length; i++) {
			printer = services[i].getName();
			if (printer.equalsIgnoreCase(printerToUse.toString())) {
				//System.out.println("This is the printer I will use "
				//+ printerName);
				ps = services[i];
				//bugzilla 2380: load all valid printer names for error message
				//break;
			}
		}

		if (ps == null) {
			LogEvent.logError("SampleLabelPrintProvider", "printLabels()", StringUtil.getMessageForKey("errors.labelprint.no.printer"));
			return FWD_FAIL_BAD_PRINTER;
		}
		
		return FWD_SUCCESS;
	}

	private String[] generateAccessionList(String accessionCount, String accessionStart, String accessionEnd) {
		int total = 0;
		String[] list = null;

		if (StringUtil.isNullorNill(accessionStart) && StringUtil.isNullorNill(accessionEnd)) {
			total = Integer.parseInt(accessionCount);
			list = new String[total];
			for (int i = 0; i < total; i++) {
				list[i] = AccessionNumberUtil.getNextAccessionNumber(null);
			}
		} else if (StringUtil.isNullorNill(accessionStart)) {
			list = new String[1];
			list[0] = accessionEnd;
		} else if (StringUtil.isNullorNill(accessionEnd)) {
			list = new String[1];
			list[0] = accessionStart;
		} else {
			String prefix = accessionStart.substring(0, AccessionNumberUtil.getInvarientLength());
			String start = accessionStart.substring(AccessionNumberUtil.getInvarientLength());
			String end = accessionEnd.substring(AccessionNumberUtil.getInvarientLength());
			total = Integer.parseInt(end) - Integer.parseInt(start) + 1;
			list = new String[total];
			list[0] = accessionStart;
			list[total - 1] = accessionEnd;
			int changeableLength = AccessionNumberUtil.getChangeableLength();
			for (int i = 1; i < total - 1; i++) {
				list[i] = prefix + String.format("%0" + Integer.toString(changeableLength) + "d", Integer.parseInt(start) + i);
			}
		}

		return list;
	}

	private void initializeLabelData() {
		for (Entry<Property, Property> prop : propList.entrySet()) {
			labelData.put(prop.getKey().name().toString(),
				ConfigurationProperties.getInstance().getPropertyValue(prop.getValue()) + " " + StringUtil.getMessageForKey("sample.label.print.init"));
		}
	}

	private void updateLabelData(String value, String separator, Property[] keys) {
		if (!GenericValidator.isBlankOrNull(value)) {
			for (Property key : keys) {
				if (!GenericValidator.isBlankOrNull(labelData.get(key))) {
					value = labelData.get(key) + separator + value;
				}
				labelData.put(key.name().toString(), value);
			}
		}
	}
	
	private void updateLabelSampleData() {
		updateLabelData(accessionNumber + (itemCount > 0 ? " (" + itemCount + ")" : ""), "",
						new Property[] { Property.MASTER_LABELS_ACCESSION });
		updateLabelData(accessionNumber, "",
						new Property[] { Property.SPECIMEN_LABELS_ACCESSION });
		if (existingSampleItemTypes != null)
			updateLabelData(StringUtil.join(existingSampleItemTypes, ", "), ", ",
							new Property[] { Property.MASTER_LABELS_SPECIMEN_TYPE, Property.SPECIMEN_LABELS_SPECIMEN_TYPE });
		if (existingSampleItemSections != null)
			updateLabelData(StringUtil.join(existingSampleItemSections, ", "), ", ",
							new Property[] { Property.MASTER_LABELS_LAB_SECTIONS, Property.SPECIMEN_LABELS_LAB_SECTIONS });
		updateLabelData(sample.getCollectionDateForDisplay(), "",
						new Property[] { Property.MASTER_LABELS_COLLECTION_DATE, Property.SPECIMEN_LABELS_COLLECTION_DATE });
		updateLabelData(sample.getCollectionTimeForDisplay(), "",
						new Property[] { Property.MASTER_LABELS_COLLECTION_TIME, Property.SPECIMEN_LABELS_COLLECTION_TIME });
	}
	
	private void updateLabelPatientData() {
		updateLabelData(patientService.getPatientId(), "",
						new Property[] { Property.MASTER_LABELS_PATIENT_ID, Property.SPECIMEN_LABELS_PATIENT_ID });
		updateLabelData(patientService.getNationalId(), "",
						new Property[] { Property.MASTER_LABELS_NATIONAL_ID, Property.SPECIMEN_LABELS_NATIONAL_ID });
		updateLabelData(patientService.getSTNumber(), "",
						new Property[] { Property.MASTER_LABELS_PATIENT_MRN, Property.SPECIMEN_LABELS_PATIENT_MRN });
		updateLabelData(patientService.getFirstName() + " " + patientService.getLastName(), "",
						new Property[] { Property.MASTER_LABELS_PATIENT_NAME, Property.SPECIMEN_LABELS_PATIENT_NAME });
		updateLabelData(patientService.getDOB(), "",
						new Property[] { Property.MASTER_LABELS_PATIENT_DOB, Property.SPECIMEN_LABELS_PATIENT_DOB });
		updateLabelData(GenericValidator.isBlankOrNull(patientService.getDOB()) ?
							null : DateUtil.getCurrentAgeForDate(DateUtil.convertAmbiguousStringDateToTimestamp(patientService.getDOB()),
						new Timestamp(new java.util.Date().getTime())), "",
						new Property[] { Property.MASTER_LABELS_PATIENT_AGE, Property.SPECIMEN_LABELS_PATIENT_AGE });
		updateLabelData(patientService.getGender(), "",
						new Property[] { Property.MASTER_LABELS_PATIENT_SEX, Property.SPECIMEN_LABELS_PATIENT_SEX });
	}

	private void initializeLabelProperties() {
		// Print order hard-coded for now, not sure if it needs to be configurable or not
		masterPrintOrder.add(Property.MASTER_LABELS_ACCESSION);
		masterPrintOrder.add(Property.MASTER_LABELS_COLLECTION_DATE);
		masterPrintOrder.add(Property.MASTER_LABELS_COLLECTION_TIME);
		masterPrintOrder.add(Property.MASTER_LABELS_PATIENT_ID);
		masterPrintOrder.add(Property.MASTER_LABELS_NATIONAL_ID);
		masterPrintOrder.add(Property.MASTER_LABELS_PATIENT_MRN);
		masterPrintOrder.add(Property.MASTER_LABELS_PATIENT_NAME);
		masterPrintOrder.add(Property.MASTER_LABELS_PATIENT_DOB);
		masterPrintOrder.add(Property.MASTER_LABELS_PATIENT_AGE);
		masterPrintOrder.add(Property.MASTER_LABELS_PATIENT_SEX);
		masterPrintOrder.add(Property.MASTER_LABELS_LAB_SECTIONS);
		masterPrintOrder.add(Property.MASTER_LABELS_SPECIMEN_TYPE);

		itemPrintOrder.add(Property.SPECIMEN_LABELS_ACCESSION);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_COLLECTION_DATE);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_COLLECTION_TIME);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_PATIENT_ID);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_NATIONAL_ID);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_PATIENT_MRN);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_PATIENT_NAME);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_PATIENT_DOB);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_PATIENT_AGE);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_PATIENT_SEX);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_LAB_SECTIONS);
		itemPrintOrder.add(Property.SPECIMEN_LABELS_SPECIMEN_TYPE);

		// match up label properties with their prefixes
		propList.put(Property.MASTER_LABELS_ACCESSION, Property.MASTER_PREFIX_ACCESSION);
		propList.put(Property.MASTER_LABELS_COLLECTION_DATE, Property.MASTER_PREFIX_COLLECTION_DATE);
		propList.put(Property.MASTER_LABELS_COLLECTION_TIME, Property.MASTER_PREFIX_COLLECTION_TIME);
		propList.put(Property.MASTER_LABELS_PATIENT_ID, Property.MASTER_PREFIX_PATIENT_ID);
		propList.put(Property.MASTER_LABELS_NATIONAL_ID, Property.MASTER_PREFIX_NATIONAL_ID);
		propList.put(Property.MASTER_LABELS_PATIENT_MRN, Property.MASTER_PREFIX_PATIENT_MRN);
		propList.put(Property.MASTER_LABELS_PATIENT_NAME, Property.MASTER_PREFIX_PATIENT_NAME);
		propList.put(Property.MASTER_LABELS_PATIENT_DOB, Property.MASTER_PREFIX_PATIENT_DOB);
		propList.put(Property.MASTER_LABELS_PATIENT_AGE, Property.MASTER_PREFIX_PATIENT_AGE);
		propList.put(Property.MASTER_LABELS_PATIENT_SEX, Property.MASTER_PREFIX_PATIENT_SEX);
		propList.put(Property.MASTER_LABELS_LAB_SECTIONS, Property.MASTER_PREFIX_LAB_SECTIONS);
		propList.put(Property.MASTER_LABELS_SPECIMEN_TYPE, Property.MASTER_PREFIX_SPECIMEN_TYPE);
		propList.put(Property.SPECIMEN_LABELS_ACCESSION, Property.SPECIMEN_PREFIX_ACCESSION);
		propList.put(Property.SPECIMEN_LABELS_COLLECTION_DATE, Property.SPECIMEN_PREFIX_COLLECTION_DATE);
		propList.put(Property.SPECIMEN_LABELS_COLLECTION_TIME, Property.SPECIMEN_PREFIX_COLLECTION_TIME);
		propList.put(Property.SPECIMEN_LABELS_PATIENT_ID, Property.SPECIMEN_PREFIX_PATIENT_ID);
		propList.put(Property.SPECIMEN_LABELS_NATIONAL_ID, Property.SPECIMEN_PREFIX_NATIONAL_ID);
		propList.put(Property.SPECIMEN_LABELS_PATIENT_MRN, Property.SPECIMEN_PREFIX_PATIENT_MRN);
		propList.put(Property.SPECIMEN_LABELS_PATIENT_NAME, Property.SPECIMEN_PREFIX_PATIENT_NAME);
		propList.put(Property.SPECIMEN_LABELS_PATIENT_DOB, Property.SPECIMEN_PREFIX_PATIENT_DOB);
		propList.put(Property.SPECIMEN_LABELS_PATIENT_AGE, Property.SPECIMEN_PREFIX_PATIENT_AGE);
		propList.put(Property.SPECIMEN_LABELS_PATIENT_SEX, Property.SPECIMEN_PREFIX_PATIENT_SEX);
		propList.put(Property.SPECIMEN_LABELS_LAB_SECTIONS, Property.SPECIMEN_PREFIX_LAB_SECTIONS);
		propList.put(Property.SPECIMEN_LABELS_SPECIMEN_TYPE, Property.SPECIMEN_PREFIX_SPECIMEN_TYPE);
	}

	private void runPrintJobs() throws PrintException {
		returnedData += ";;";
		
		if (masterCount > 0) {
			DocPrintJob masterJob = ps.createPrintJob();

			PrintRequestAttributeSet masterAset = new HashPrintRequestAttributeSet();
			masterAset.add(new Copies(masterCount));

			String masterLabel = "";
			String masterZPL = StringUtil.getMessageForKey("master.label.zpl.prefix"); //"^XA";
			for (Property prop : masterPrintOrder) {
				if (ConfigurationProperties.getInstance().isPropertyValueEqual(prop, "true")) {
					masterLabel += (!GenericValidator.isBlankOrNull(labelData.get(prop.name().toString())) ?
									labelData.get(prop.name().toString()) : "") + "\n";
					if (prop.equals(Property.MASTER_LABELS_ACCESSION)) {
						masterZPL += StringUtil.getMessageForKey("master.label.zpl.accession.barcode.prefix") //"^FO20,30^BCN,60,N,N,N^FD"
								  + labelData.get(prop.name().toString())
								  + StringUtil.getMessageForKey("master.label.zpl.accession.text.prefix") //"^FS^FO30,90^AEN,12,18^FD"
								  + labelData.get(prop.name().toString())
								  + StringUtil.getMessageForKey("master.label.zpl.accession.suffix"); //"^FS";
					} else {
						masterZPL += StringUtil.getMessageForKey("master.label.zpl.other.prefix") //"^FO25,195^AEN,12,18^FD"
								  + labelData.get(prop.name().toString())
								  + StringUtil.getMessageForKey("master.label.zpl.other.suffix"); //"^FS";
					}
				}
			}
			masterZPL += StringUtil.getMessageForKey("master.label.zpl.suffix"); //"^XZ";

			// Printing raw ZPL and returning the ZPL string that can be displayed via JavaScript as a simulated label in the browser
//			System.out.println("Master Label (" + masterCount + " copies):\n" + masterLabel);
//			System.out.println("Master Label ZPL (" + masterCount + " copies):\n" + masterZPL + "\n");
			returnedData += masterZPL;

			byte[] byt = masterZPL.getBytes();
			DocFlavor flavor = DocFlavor.BYTE_ARRAY.AUTOSENSE;
			Doc doc = new SimpleDoc(byt, flavor, null);
			masterJob.addPrintJobListener(new MyPrintJobListener());
			masterJob.print(doc, masterAset);
		}

		returnedData += ";;";
		
		for (int j = 1; j <= itemCount; j++) {
			DocPrintJob itemJob = ps.createPrintJob();
			PrintRequestAttributeSet itemAset = new HashPrintRequestAttributeSet();
			itemAset.add(new Copies(1));

			String itemLabel = "";
			String itemZPL = StringUtil.getMessageForKey("item.label.zpl.prefix"); //"^XA";
			for (Property prop : itemPrintOrder) {
				if (ConfigurationProperties.getInstance().isPropertyValueEqual(prop, "true")) {
					itemLabel += !GenericValidator.isBlankOrNull(labelData.get(prop.name().toString())) ?
								 labelData.get(prop.name().toString()) : "";
					if (prop.equals(Property.SPECIMEN_LABELS_ACCESSION)) {
						itemLabel += "-" + j;
						itemZPL += StringUtil.getMessageForKey("item.label.zpl.accession.barcode.prefix") //"^FO20,30^BCN,60,N,N,N^FD"
								+ labelData.get(prop.name().toString()) + "-" + j
								+ StringUtil.getMessageForKey("item.label.zpl.accession.text.prefix") //"^FS^FO30,90^AEN,12,18^FD"
								+ labelData.get(prop.name().toString()) + "-" + j
								+ StringUtil.getMessageForKey("item.label.zpl.accession.suffix"); //"^FS";
					} else {
						itemZPL += StringUtil.getMessageForKey("item.label.zpl.other.prefix") //"^FO25,195^AEN,12,18^FD"
								+ labelData.get(prop.name().toString())
								+ StringUtil.getMessageForKey("item.label.zpl.other.suffix"); //"^FS";
					}
					itemLabel += "\n";	
				}				
			}
			itemZPL += StringUtil.getMessageForKey("item.label.zpl.suffix"); //"^XZ";

			// Printing raw ZPL and returning a ZPL string that can be displayed via JavaScript as a simulated label in the browser
//			System.out.println("Item Label:\n" + itemLabel);				
//			System.out.println("Item Label ZPL:\n" + itemZPL + "\n");
			returnedData += "::" + itemZPL;

			byte[] byt = itemZPL.getBytes();
			DocFlavor flavor = DocFlavor.BYTE_ARRAY.AUTOSENSE;
			Doc doc = new SimpleDoc(byt, flavor, null);
			itemJob.addPrintJobListener(new MyPrintJobListener());
			itemJob.print(doc, itemAset);
		}
		
		//String label = SystemConfiguration.getInstance()
		//		.getDefaultSampleLabel(accessionNumber);

		//byte[] byt = label.getBytes();
		//DocFlavor flavor = DocFlavor.BYTE_ARRAY.AUTOSENSE;
		//Doc doc = new SimpleDoc(byt, flavor, null);
		//job.addPrintJobListener(new MyPrintJobListener());
		//job.print(doc, aset);
	}

	/**
	 * Get all printer's names in server system
	 * 
	 * @return printServiceNames : String List
	 */
	public List<String> getAllSystemPrintServiceNames() {
		List<String> printServiceNames = new ArrayList<String>();
		PrintService[] services = PrintServiceLookup.lookupPrintServices(
				null, null);
		if (services != null) {
			for (int i = 0; i < services.length; i++) {
				if (services[i] != null) {
					printServiceNames.add(services[i].getName());
				}
			}
		}
		return printServiceNames;
	}
	
	class MyPrintJobListener implements PrintJobListener {
		public void printDataTransferCompleted(PrintJobEvent pje) {
			System.out
					.println("The print data has been transferred to the print service");
		}

		public void printJobCanceled(PrintJobEvent pje) {
			System.out.println("The print job was cancelled");
		}

		public void printJobCompleted(PrintJobEvent pje) {
			System.out.println("The print job was completed");
		}

		public void printJobFailed(PrintJobEvent pje) {
			System.out.println("The print job has failed");
		}

		public void printJobNoMoreEvents(PrintJobEvent pje) {
			System.out
					.println("No more events will be delivered from this print service for this print job.");
			// No more events will be delivered from this
			// print service for this print job.
			// This event is fired in cases where the print service
			// is not able to determine when the job completes.
		}

		public void printJobRequiresAttention(PrintJobEvent pje) {
			System.out
					.println("The print service requires some attention to repair some problem. E.g. running out of paper would");
			// The print service requires some attention to repair
			// some problem. E.g. running out of paper would
			// cause this event to be fired.
		}
	}

}
