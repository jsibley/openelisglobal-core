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
package us.mn.state.health.lims.common.provider.validation;

import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.apache.commons.validator.GenericValidator;

import us.mn.state.health.lims.common.action.IActionConstants;
import us.mn.state.health.lims.common.formfields.FormFields;
import us.mn.state.health.lims.common.formfields.FormFields.Field;
import us.mn.state.health.lims.common.log.LogEvent;
import us.mn.state.health.lims.common.services.StatusService;
import us.mn.state.health.lims.common.services.StatusService.SampleStatus;
import us.mn.state.health.lims.common.util.ConfigurationProperties;
import us.mn.state.health.lims.common.util.DateUtil;
import us.mn.state.health.lims.common.util.StringUtil;
import us.mn.state.health.lims.common.util.SystemConfiguration;
import us.mn.state.health.lims.common.util.ConfigurationProperties.Property;
import us.mn.state.health.lims.common.util.resources.ResourceLocator;
import us.mn.state.health.lims.sample.dao.SampleDAO;
import us.mn.state.health.lims.sample.daoimpl.SampleDAOImpl;
import us.mn.state.health.lims.sample.valueholder.Sample;
import us.mn.state.health.lims.sampleitem.dao.SampleItemDAO;
import us.mn.state.health.lims.sampleitem.daoimpl.SampleItemDAOImpl;
import us.mn.state.health.lims.sampleitem.valueholder.SampleItem;

public class YearSiteNumAccessionValidator implements IAccessionNumberValidator {
	protected static final String INCREMENT_STARTING_VALUE = "000001";
	protected static final int UPPER_INC_RANGE = 999999;
	protected static final int SITE_START = getSiteStartIndex();
	protected static final int SITE_END = getSiteEndIndex();
	protected static final int YEAR_START = getYearStartIndex();
	protected static final int YEAR_END = getYearEndIndex();
	protected static final int INCREMENT_START = getIncrementStartIndex();
	protected final int INCREMENT_END = getMaxAccessionLength();
	protected final int LENGTH = getMaxAccessionLength();
	protected static final boolean NEED_PROGRAM_CODE = false;
	private static final Set<String> REQUESTED_NUMBERS = new HashSet<String>();

	public boolean needProgramCode() {
		return NEED_PROGRAM_CODE;
	}

	// input parameter is not used in this case
	public String createFirstAccessionNumber(String nullPrefix) {
		StringBuilder builder = new StringBuilder(DateUtil.getTwoDigitYear());

		builder.append(getSite());
		builder.append(INCREMENT_STARTING_VALUE);
		return builder.toString();
	}

	public String getInvalidMessage(ValidationResults results) {
		String suggestedAccessionNumber = getNextAvailableAccessionNumber(null);

		StringBuilder builder = new StringBuilder();

		String configLocale = SystemConfiguration.getInstance().getDefaultLocale().toString();
		Locale locale = new Locale(configLocale);

		String message = ResourceLocator.getInstance().getMessageResources().getMessage(locale,
				"sample.entry.invalid.accession.number.suggestion");

		builder.append(message);
		builder.append(" ");
		builder.append(suggestedAccessionNumber);

		return builder.toString();

	}

	// input parameter is not used in this case
	public String getNextAvailableAccessionNumber(String nullPrefix) {

		String nextAccessionNumber = null;

		SampleDAO sampleDAO = new SampleDAOImpl();

		String curLargestAccessionNumber = sampleDAO.getLargestAccessionNumberWithPrefix(createFirstAccessionNumber(null).substring(YEAR_START, SITE_END));

		try {
			if (curLargestAccessionNumber == null) {
				if( REQUESTED_NUMBERS.isEmpty()){
					nextAccessionNumber = createFirstAccessionNumber(null);
				}else{
					nextAccessionNumber = REQUESTED_NUMBERS.iterator().next();
				}
			} else {
				nextAccessionNumber = incrementAccessionNumber(curLargestAccessionNumber);
			}

			while( REQUESTED_NUMBERS.contains(nextAccessionNumber) ){
				nextAccessionNumber = incrementAccessionNumber(nextAccessionNumber);
			}
		} catch (IllegalArgumentException e) {
			e.printStackTrace();
			LogEvent.logError("YearSiteNumAccessionValidator","getNextAvailableAccessionNumber()", StringUtil.getMessageForKey("error.accession.no.next"));
			nextAccessionNumber = null;
		}
		
		REQUESTED_NUMBERS.add(nextAccessionNumber);
		
		return nextAccessionNumber;
	}

	public String incrementAccessionNumber(String currentHighAccessionNumber) throws IllegalArgumentException {
		// if the year differs then start the sequence again. If not then
		// increment but check for overflow into year
		int year = new GregorianCalendar().get(Calendar.YEAR) - 2000;

		try {
			if (year != Integer.parseInt(currentHighAccessionNumber.substring(YEAR_START, YEAR_END))) {
				return createFirstAccessionNumber(null);
			}
		} catch (NumberFormatException nfe) {
			return createFirstAccessionNumber(null);
		}

		int increment = Integer.parseInt(currentHighAccessionNumber.substring(INCREMENT_START));
		String incrementAsString = INCREMENT_STARTING_VALUE;

		if (increment < UPPER_INC_RANGE) {
			increment++;
			incrementAsString = String.format("%06d", increment);
		} else {
			throw new IllegalArgumentException("AccessionNumber has no next value");
		}

		StringBuilder builder = new StringBuilder(currentHighAccessionNumber.substring(YEAR_START, SITE_END));
		builder.append(incrementAsString);

		return builder.toString();
	}

	// recordType parameter is not used in this case
	public boolean accessionNumberIsUsed(String accessionNumber, String recordType) {

		SampleDAO SampleDAO = new SampleDAOImpl();
		if (!FormFields.getInstance().useField(Field.LAB_NUMBER_USED_ONLY_IF_SPECIMENS)) {
			return SampleDAO.getSampleByAccessionNumber(accessionNumber) != null;
		} else {
			SampleItemDAO sampleItemDAO = new SampleItemDAOImpl();
			Sample sample = null;
			Set<Integer> includedSampleStatusList;

			includedSampleStatusList = new HashSet<Integer>();
			includedSampleStatusList.add(Integer.parseInt(StatusService.getInstance().getStatusID(SampleStatus.Entered)));

			sample = SampleDAO.getSampleByAccessionNumber(accessionNumber);
			if (sample == null || GenericValidator.isBlankOrNull(sample.getId())) {
				return false;
			} else {
				List<SampleItem> sampleItemList = sampleItemDAO.getSampleItemsBySampleIdAndStatus(sample.getId(), includedSampleStatusList);
				return !sampleItemList.isEmpty();
			}
		}
	}

	public ValidationResults checkAccessionNumberValidity(String accessionNumber, String recordType, String isRequired,
			String projectFormName) {

			ValidationResults results = validFormat(accessionNumber, true);
			//TODO refactor accessionNumberIsUsed into two methods so the null isn't needed. (Its only used for program accession number)
			if (results == ValidationResults.SUCCESS && accessionNumberIsUsed(accessionNumber, null)) {
				results = ValidationResults.USED_FAIL;
			}

			return results;
	}

	public ValidationResults validFormat(String accessionNumber, boolean checkDate) {
		if (accessionNumber.length() != LENGTH) {
			return ValidationResults.LENGTH_FAIL;
		}

		if (!accessionNumber.substring(SITE_START, SITE_END).equals( getSite())) {
			return ValidationResults.SITE_FAIL;
		}

		

		if (checkDate) {
			int year = new GregorianCalendar().get(Calendar.YEAR);
			try {
				if ((year - 2000) != Integer.parseInt(accessionNumber.substring(YEAR_START, YEAR_END))) {
					return ValidationResults.YEAR_FAIL;
				}
			} catch (NumberFormatException nfe) {
				return ValidationResults.YEAR_FAIL;
			}
		}else{
			try { //quick and dirty to make sure they are digits
				Integer.parseInt(accessionNumber.substring(YEAR_START, YEAR_END));
			} catch (NumberFormatException nfe) {
				return ValidationResults.YEAR_FAIL;
			}
		}

		try {
			Integer.parseInt(accessionNumber.substring(INCREMENT_START));
		} catch (NumberFormatException e) {
			return ValidationResults.FORMAT_FAIL;
		}

		return ValidationResults.SUCCESS;
	}


    public String getInvalidFormatMessage( ValidationResults results ){
        return StringUtil.getMessageForKey( "sample.entry.invalid.accession.number.format.corrected", getFormatPattern(), getFormatExample() );
    }

    private String getFormatPattern(){
        StringBuilder format = new StringBuilder();
        format.append( StringUtil.getMessageForKey( "date.two.digit.year" ) );
		format.append("SS");
        for( int i = 0; i < getChangeableLength(); i++){
            format.append( "#" );
        }
        return format.toString();
    }

    private String getFormatExample(){
        StringBuilder format = new StringBuilder();
        format.append( DateUtil.getTwoDigitYear() );
		format.append(getSite());
        for( int i = 0; i < getChangeableLength() - 1; i++){
            format.append( "0" );
        }

        format.append( "1" );

        return format.toString();
    }

	public int getMaxAccessionLength() {
		return getSiteEndIndex() + INCREMENT_STARTING_VALUE.length();
	}
	
	protected static int getIncrementStartIndex() {
		return getSiteEndIndex();
	}

	protected static int getSiteStartIndex() {
		return getYearEndIndex();
	}

	protected static int getSiteEndIndex() {
		return getSiteStartIndex() + getSite().length();
	}

	protected static int getYearStartIndex() {
		return 0;
	}

	protected static int getYearEndIndex() {
		return getYearStartIndex() + 2;
	}

	@Override
	public int getInvarientLength() {
		return getSiteEndIndex();
	}

	public int getChangeableLength() {
		return getMaxAccessionLength() - getInvarientLength();
	}

	protected static String getSite() {
		return ConfigurationProperties.getInstance().getPropertyValue(Property.SiteCode);
	}

	@Override
	public String getPrefix() {
		return null; //no single prefix
	}
}