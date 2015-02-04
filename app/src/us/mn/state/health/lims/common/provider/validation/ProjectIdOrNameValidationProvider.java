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
package us.mn.state.health.lims.common.provider.validation;

import java.io.IOException;
import java.net.URLDecoder;
import java.util.LinkedHashMap;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import us.mn.state.health.lims.common.exception.LIMSRuntimeException;
import us.mn.state.health.lims.common.servlet.validation.AjaxServlet;
import us.mn.state.health.lims.common.util.StringUtil;
import us.mn.state.health.lims.common.log.LogEvent;
import us.mn.state.health.lims.project.dao.ProjectDAO;
import us.mn.state.health.lims.project.daoimpl.ProjectDAOImpl;
import us.mn.state.health.lims.project.valueholder.Project;
/**
 * @author benzd1
 * bugzilla 1978 ProjectIdOrNameValidationProvider: only allows active projects
 */
public class ProjectIdOrNameValidationProvider extends BaseValidationProvider {

	public ProjectIdOrNameValidationProvider() {
		super();
	}

	public ProjectIdOrNameValidationProvider(AjaxServlet ajaxServlet) {
		this.ajaxServlet = ajaxServlet;
	}

	public void processRequest(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {

		// need to use 'URLDecoder.decode' since calling 'request.getParameter' directly does not handle the encoding properly
		String decodedRequest = URLDecoder.decode(request.getQueryString(), "UTF-8");
		Map<String, String> paramMap = new LinkedHashMap<String, String>();
		for (String paramPair : decodedRequest.split("&")) {
		   String[] pairs = paramPair.split("=", 2);
		   paramMap.put(pairs[0], pairs[1]);
		}
		String targetId = (String) paramMap.get("id");
		String formField = (String) paramMap.get("field");
		String result = validate(targetId);
		// System.out.println("This is field being validated " + formField);
		ajaxServlet.sendData(formField, result, request, response);
	}

	public String validate(String targetId) throws LIMSRuntimeException {
		StringBuffer s = new StringBuffer();
		try {
			ProjectDAO projectDAO = new ProjectDAOImpl();
			Project project = new Project();
			if (StringUtil.isInteger(targetId) && !targetId.startsWith("-")) {
				project.setLocalAbbreviation(targetId.trim());
				project = projectDAO.getProjectById(targetId.trim());
			} else if (!StringUtil.isNullorNill(targetId.trim())){
				project.setId("");
				project.setProjectName(targetId.trim());
				project = projectDAO.getProjectByName(project, true, true);
			} else {
				s.append(INVALID);
				return s.toString();
			}
			
			if (null != project) {
				if (project.getIsActive().equals(YES)) {
					// This is particular to projId validation for HSE1 and HSE2:
					// the message appended to VALID is the projectName that
					// can then be displayed when User enters valid Project Id
					// (see humanSampleOne.jsp, humanSampleTwo.jsp)
				
					s.append(VALID);
					if (StringUtil.isInteger(targetId) && !targetId.startsWith("-")) {
						 if (null != project.getProjectName())
							 s.append(project.getProjectName());
					} else 
						s.append(project.getId());
				}				
			}
			if (s.length() == 0) {
				s.append(INVALID);
			}
		} catch (Exception e) {
			LogEvent.logError("ProjectIdOrNameValidationProvider","validate()",e.toString());
			s.append(INVALID);
		}
				
		return s.toString();
	}
}
