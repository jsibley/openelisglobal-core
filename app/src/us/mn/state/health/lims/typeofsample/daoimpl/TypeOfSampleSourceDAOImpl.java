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
package us.mn.state.health.lims.typeofsample.daoimpl;

import java.util.List;
import java.util.Vector;

import org.apache.commons.beanutils.PropertyUtils;
import org.hibernate.Query;

import us.mn.state.health.lims.audittrail.dao.AuditTrailDAO;
import us.mn.state.health.lims.audittrail.daoimpl.AuditTrailDAOImpl;
import us.mn.state.health.lims.common.action.IActionConstants;
import us.mn.state.health.lims.common.daoimpl.BaseDAOImpl;
import us.mn.state.health.lims.common.exception.LIMSRuntimeException;
import us.mn.state.health.lims.common.log.LogEvent;
import us.mn.state.health.lims.hibernate.HibernateUtil;
import us.mn.state.health.lims.typeofsample.dao.TypeOfSampleSourceDAO;
import us.mn.state.health.lims.typeofsample.valueholder.TypeOfSampleSource;

public class TypeOfSampleSourceDAOImpl extends BaseDAOImpl implements TypeOfSampleSourceDAO {

	public void deleteData(String[] typeOfSamplesSourceIDs, String currentUserId) throws LIMSRuntimeException {

		try {
			AuditTrailDAO auditDAO = new AuditTrailDAOImpl();
			for (String id : typeOfSamplesSourceIDs) {
				TypeOfSampleSource data = (TypeOfSampleSource) readTypeOfSampleSource(id);
				
				auditDAO.saveHistory(new TypeOfSampleSource(), data, currentUserId, IActionConstants.AUDIT_TRAIL_DELETE, "SAMPLETYPE_SOURCE");
				HibernateUtil.getSession().delete(data);
				HibernateUtil.getSession().flush();
				HibernateUtil.getSession().clear();
			}

		} catch (Exception e) {
			// bugzilla 2154
			LogEvent.logError("TypeOfSampleSourceDAOImpl", "deleteData()", e.toString());
			throw new LIMSRuntimeException("Error in TypeOfSampleSource deleteData()", e);
		}
	}

	public boolean insertData(TypeOfSampleSource typeOfSampleSource) throws LIMSRuntimeException {

		try {

			String id = (String)HibernateUtil.getSession().save(typeOfSampleSource);

			typeOfSampleSource.setId(id);
			AuditTrailDAO auditDAO = new AuditTrailDAOImpl();
			auditDAO.saveNewHistory(typeOfSampleSource, typeOfSampleSource.getSysUserId(), "SAMPLETYPE_SOURCE");
			HibernateUtil.getSession().flush();
			HibernateUtil.getSession().clear();
		} catch (Exception e) {
			LogEvent.logError("TypeOfSampleSourceDAOImpl", "insertData()", e.toString());
			throw new LIMSRuntimeException("Error in TypeOfSampleSource insertData()", e);
		}

		return true;
	}

	public void getData(TypeOfSampleSource typeOfSampleSource) throws LIMSRuntimeException {

		try {
			TypeOfSampleSource tos = (TypeOfSampleSource) HibernateUtil.getSession().get(TypeOfSampleSource.class,
					typeOfSampleSource.getId());
			HibernateUtil.getSession().flush();
			HibernateUtil.getSession().clear();
			if (tos != null) {
				PropertyUtils.copyProperties(typeOfSampleSource, tos);
			} else {
				typeOfSampleSource.setId(null);
			}
		} catch (Exception e) {
			LogEvent.logError("TypeOfSampleSourceDAOImpl", "getData()", e.toString());
			throw new LIMSRuntimeException("Error in TypeOfSampleSource getData()", e);
		}
	}

	public List getAllTypeOfSampleSources() throws LIMSRuntimeException {

		List list = new Vector();
		try {
			String sql = "from TypeOfSampleSource";
			org.hibernate.Query query = HibernateUtil.getSession().createQuery(sql);
			// query.setMaxResults(10);
			// query.setFirstResult(3);
			list = query.list();
			HibernateUtil.getSession().flush();
			HibernateUtil.getSession().clear();
		} catch (Exception e) {
			// bugzilla 2154
			LogEvent.logError("TypeOfSampleSourceDAOImpl", "getAllTypeOfSampleSources()", e.toString());
			throw new LIMSRuntimeException("Error in TypeOfSampleSource getAllTypeOfSampleSources()", e);
		}

		return list;
	}

	public List getPageOfTypeOfSampleSource(int startingRecNo) throws LIMSRuntimeException {

		List list = new Vector();
		try {
			// calculate maxRow to be one more than the page size
			int endingRecNo = startingRecNo + DEFAULT_PAGE_SIZE + 1;

			String sql = "from TypeOfSampleSource t order by t.typeOfSampleId, t.sourceId";
			org.hibernate.Query query = HibernateUtil.getSession().createQuery(sql);
			query.setFirstResult(startingRecNo - 1);
			query.setMaxResults(endingRecNo - 1);
			list = query.list();
			HibernateUtil.getSession().flush();
			HibernateUtil.getSession().clear();
		} catch (Exception e) {
			LogEvent.logError("TypeOfSampleSourceDAOImpl", "getPageOfTypeOfSampleSources()", e.toString());
			throw new LIMSRuntimeException("Error in TypeOfSampleSource getPageOfTypeOfSampleSource()", e);
		}

		return list;
	}

	public TypeOfSampleSource readTypeOfSampleSource(String idString) {
		TypeOfSampleSource tos = null;
		try {
			tos = (TypeOfSampleSource) HibernateUtil.getSession().get(TypeOfSampleSource.class, idString);
			HibernateUtil.getSession().flush();
			HibernateUtil.getSession().clear();
		} catch (Exception e) {
			// bugzilla 2154
			LogEvent.logError("TypeOfSampleSourceDAOImpl", "readTypeOfSampleSource()", e.toString());
			throw new LIMSRuntimeException("Error in TypeOfSampleSource readTypeOfSampleSource()", e);
		}

		return tos;
	}

	public List getNextTypeOfSampleSourceRecord(String id) throws LIMSRuntimeException {

		return getNextRecord(id, "TypeOfSampleSource", TypeOfSampleSource.class);
	}

	public List getPreviousTypeOfSampleSourceRecord(String id) throws LIMSRuntimeException {

		return getPreviousRecord(id, "TypeOfSampleSource", TypeOfSampleSource.class);
	}

	public Integer getTotalTypeOfSampleSourceCount() throws LIMSRuntimeException {
		return getTotalCount("TypeOfSampleSource", TypeOfSampleSource.class);
	}

	public List getNextRecord(String id, String table, Class clazz) throws LIMSRuntimeException {
		int currentId = (Integer.valueOf(id)).intValue();
		String tablePrefix = getTablePrefix(table);

		List list = new Vector();
		// bugzilla 1908
		int rrn = 0;
		try {
			// bugzilla 1908 cannot use named query for postgres because of
			// oracle ROWNUM
			// instead get the list in this sortorder and determine the index of
			// record with id = currentId
			String sql = "select tos.id from TypeOfSampleTest tos " + " order by tos.domain, tos.description";

			org.hibernate.Query query = HibernateUtil.getSession().createQuery(sql);
			list = query.list();
			HibernateUtil.getSession().flush();
			HibernateUtil.getSession().clear();
			rrn = list.indexOf(String.valueOf(currentId));

			list = HibernateUtil.getSession().getNamedQuery(tablePrefix + "getNext").setFirstResult(rrn + 1)
					.setMaxResults(2).list();

		} catch (Exception e) {
			// bugzilla 2154
			LogEvent.logError("TypeOfSampleDAOImpl", "getNextRecord()", e.toString());
			throw new LIMSRuntimeException("Error in getNextRecord() for " + table, e);
		}

		return list;
	}

	public List getPreviousRecord(String id, String table, Class clazz) throws LIMSRuntimeException {
		int currentId = (Integer.valueOf(id)).intValue();
		String tablePrefix = getTablePrefix(table);

		List list = new Vector();
		// bugzilla 1908
		int rrn = 0;
		try {
			// bugzilla 1908 cannot use named query for postgres because of
			// oracle ROWNUM
			// instead get the list in this sortorder and determine the index of
			// record with id = currentId
			String sql = "select tos.id from TypeOfSampleTest tos " + " order by tos.domain desc, tos.description desc";

			org.hibernate.Query query = HibernateUtil.getSession().createQuery(sql);
			list = query.list();
			HibernateUtil.getSession().flush();
			HibernateUtil.getSession().clear();
			rrn = list.indexOf(String.valueOf(currentId));

			list = HibernateUtil.getSession().getNamedQuery(tablePrefix + "getPrevious").setFirstResult(rrn + 1)
					.setMaxResults(2).list();

		} catch (Exception e) {
			// bugzilla 2154
			LogEvent.logError("TypeOfSampleDAOImpl", "getPreviousRecord()", e.toString());
			throw new LIMSRuntimeException("Error in getPreviousRecord() for " + table, e);
		}

		return list;
	}

	@SuppressWarnings("unchecked")
	public List<TypeOfSampleSource> getTypeOfSampleSourcesForSampleType(String sampleType) {
			List<TypeOfSampleSource> list;

			String sql = "from TypeOfSampleSource tp where tp.typeOfSampleId = :sampleId order by tp.sourceId";

			try {
				Query query = HibernateUtil.getSession().createQuery(sql);
				query.setInteger("sampleId", Integer.parseInt(sampleType));
				list = query.list();
				HibernateUtil.getSession().flush();
				HibernateUtil.getSession().clear();
			} catch (Exception e) {
				LogEvent.logError("TypeOfSampleSourceDAOImpl", "getTypeOfSampleSourcesForSampleType", e.toString());
				throw new LIMSRuntimeException("Error in TypeOfSampleSourceDAOImpl getTypeOfSampleSourcesForSampleType", e);
			}

			return list;
		}

}