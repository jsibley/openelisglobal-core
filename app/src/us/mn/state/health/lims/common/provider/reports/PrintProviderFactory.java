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
import java.io.InputStream;
import java.util.Properties;

import us.mn.state.health.lims.common.exception.LIMSRuntimeException;
import us.mn.state.health.lims.common.util.resources.ResourceLocator;
import us.mn.state.health.lims.common.log.LogEvent;

/**
 * This class will abstract the ReportsProvider creation. It will read the
 * name of the class file from properties file and create the class
 * 
 * @version 1.0
 * @author diane benz
 * 
 */

public class PrintProviderFactory {

	private static PrintProviderFactory instance; // Instance of this

	// class

	// Properties object that holds reports provider mappings
	private Properties printProviderClassMap = null;

	/**
	 * Singleton global access for PrintProviderFactory
	 * 
	 */

	public static PrintProviderFactory getInstance() {
		if (instance == null) {
			synchronized (PrintProviderFactory.class) {
				if (instance == null) {
					instance = new PrintProviderFactory();
				}
			}

		}
		return instance;
	}

	/**
	 * Create an object for the full class name passed in.
	 * 
	 * @param String
	 *            full class name
	 * @return Object Created object
	 */
	protected Object createObject(String className) throws LIMSRuntimeException {
		Object object = null;
		try {
			Class classDefinition = Class.forName(className);
			object = classDefinition.newInstance();
		} catch (Exception e) {
			//bugzilla 2154
			LogEvent.logError("PrintProviderFactory","createObject()",e.toString());			
			throw new LIMSRuntimeException("Unable to create an object for "
					+ className, e, LogEvent.getLog(PrintProviderFactory.class));
		}
		return object;
	}

	/**
	 * Search for the PrintProvider implementation class name in the
	 * Print.properties file for the given PrintProvider name
	 * 
	 * @param String
	 *            PrintProvider name e.g
	 *            "SampleLabelPrintProvider"
	 * @return String Full implementation class e.g
	 *         "us.mn.state.health.lims.common.reports.provider"
	 */
	protected String getPrintProviderClassName(
			String printProvidername) throws LIMSRuntimeException {
		if (printProviderClassMap == null) { // Need to load the property
			// object with the class
			// mappings
			ResourceLocator rl = ResourceLocator.getInstance();
			InputStream propertyStream = null;
			// Now load a java.util.Properties object with the properties
			printProviderClassMap = new Properties();
			try {
				propertyStream = rl
						.getNamedResourceAsInputStream(ResourceLocator.REPORTS_PROPERTIES);

				printProviderClassMap.load(propertyStream);
			} catch (IOException e) {
				//bugzilla 2154
				LogEvent.logError("PrintProviderFactory","getPrintProviderClassName()",e.toString());			
				throw new LIMSRuntimeException(
						"Unable to load print provider class mappings.",
						e, LogEvent.getLog(PrintProviderFactory.class));
			} finally {
				if (null != propertyStream) {
					try {
						propertyStream.close();
						propertyStream = null;
					} catch (Exception e) {
						//bugzilla 2154
						LogEvent.logError("PrintProviderFactory","getPrintProviderClassName()",e.toString());
					}
				}
			}
		}

		String mapping = printProviderClassMap
				.getProperty(printProvidername);
		if (mapping == null) {
    		//bugzilla 2154    		
    		LogEvent.logError("PrintProviderFactory","getPrintProviderClassName()",printProvidername);
			throw new LIMSRuntimeException(
					"getPrintProviderClassName - Unable to find mapping for "
							+ printProvidername);
		}
		return mapping;
	}

	/**
	 * Print Provider creation method
	 * 
	 * @param name
	 * @return Print Provider object
	 * 
	 */
	public BasePrintProvider getPrintProvider(String name)
			throws LIMSRuntimeException {
		BasePrintProvider provider = null;

		String className = getPrintProviderClassName(name);

		provider = (BasePrintProvider) createObject(className);

		return provider;
	}

}