package us.mn.state.health.lims.typeofsample.valueholder;

import us.mn.state.health.lims.common.valueholder.BaseObject;

public class TypeOfSampleSource extends BaseObject{
	
	private static final long serialVersionUID = 1L;
	
	private String id;
	private String typeOfSampleId;
	private String sourceId;
	
	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public String getTypeOfSampleId() {
		return typeOfSampleId;
	}
	public void setTypeOfSampleId(String typeOfSampleId) {
		this.typeOfSampleId = typeOfSampleId;
	}
	public String getSourceId() {
		return sourceId;
	}
	public void setSourceId(String sourceId) {
		this.sourceId = sourceId;
	}
	
}
