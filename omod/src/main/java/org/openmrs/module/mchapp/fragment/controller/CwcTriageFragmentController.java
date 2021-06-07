package org.openmrs.module.mchapp.fragment.controller;

import org.apache.commons.lang.StringUtils;
import org.openmrs.*;
import org.openmrs.api.ProgramWorkflowService;
import org.openmrs.api.context.Context;
import org.openmrs.module.appui.UiSessionContext;
import org.openmrs.module.hospitalcore.PatientQueueService;
import org.openmrs.module.mchapp.model.ImmunizationStoreDrug;
import org.openmrs.module.hospitalcore.model.TriagePatientQueue;
import org.openmrs.module.mchapp.EhrMchMetadata;
import org.openmrs.module.mchapp.api.ImmunizationService;
import org.openmrs.module.mchapp.api.ListItem;
import org.openmrs.module.mchapp.api.MchService;
import org.openmrs.module.mchapp.api.PatientStateItem;
import org.openmrs.module.mchapp.api.model.ClinicalForm;
import org.openmrs.module.mchapp.api.parsers.QueueLogs;
import org.openmrs.module.mchapp.api.parsers.SendForExaminationParser;
import org.openmrs.module.mchapp.model.ImmunizationStorePatientTransaction;
import org.openmrs.module.patientdashboardapp.model.Referral;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.fragment.FragmentConfiguration;
import org.openmrs.ui.framework.fragment.FragmentModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestParam;

import javax.servlet.http.HttpServletRequest;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Set;

/**
 * Created by USER on 5/4/2016.
 */
public class CwcTriageFragmentController {
	
	private static ImmunizationService immunizationService = Context.getService(ImmunizationService.class);
	
	protected Logger log = LoggerFactory.getLogger(CwcTriageFragmentController.class);
	
	public void controller(FragmentModel model, FragmentConfiguration config, UiUtils ui,
	        @RequestParam(value = "encounterId", required = false) String encounterId) {
		
		if (StringUtils.isNotEmpty(encounterId)) {
			model.addAttribute("weightCategoryValue", "");
			Encounter current = Context.getEncounterService().getEncounter(Integer.parseInt(encounterId));
			
			Set<Obs> obs = Context.getEncounterService().getEncounterByUuid(current.getUuid()).getAllObs();
			for (Obs s : obs) {
				switch (s.getConcept().getId()) {
					case 5089: {
						model.addAttribute("weight", s.getValueNumeric());
						break;
					}
					case 5090: {
						model.addAttribute("height", s.getValueNumeric());
						break;
					}
					case 5712: {
						model.addAttribute("muac", s.getValueNumeric());
						break;
					}
					case 1854: {
						Concept wCat = s.getValueCoded();
						model.addAttribute("weightCategoryValue", wCat.getUuid());
						break;
					}
					case 100126186: {//use 160463
						Concept gStat = s.getValueCoded();
						model.addAttribute("growthStatusValue", gStat.getUuid());
						break;
					}
				}
			}
		} else {
			model.addAttribute("weightCategoryValue", "");
			model.addAttribute("growthStatusValue", "");
			model.addAttribute("muac", "");
			model.addAttribute("height", "");
			model.addAttribute("weight", "");
			
		}
		
		model.addAttribute("internalReferralSources",
		    SimpleObject.fromCollection(Referral.getInternalReferralOptions(), ui, "label", "id"));
		
		Concept growthCategory = Context.getConceptService().getConceptByUuid(EhrMchMetadata._MchProgram.MCH_GROWTH_MONITOR);
		List<SimpleObject> growthCategories = new ArrayList<SimpleObject>();
		
		if (growthCategory != null) {
			
			for (ConceptAnswer answer : growthCategory.getAnswers()) {
				growthCategories.add(SimpleObject.create("uuid", answer.getAnswerConcept().getUuid(), "label", answer
				        .getAnswerConcept().getDisplayString()));
			}
		}
		model.addAttribute("growthCategories", growthCategories);
		
		Concept weightCategory = Context.getConceptService().getConceptByUuid(
		    EhrMchMetadata._MchProgram.MCH_WEIGHT_CATEGORIES);
		List<SimpleObject> weightCategories = new ArrayList<SimpleObject>();
		if (weightCategory != null) {
			
			for (ConceptAnswer answer : weightCategory.getAnswers()) {
				weightCategories.add(SimpleObject.create("uuid", answer.getAnswerConcept().getUuid(), "label", answer
				        .getAnswerConcept().getDisplayString()));
			}
		}
		
		model.addAttribute("weightCategories", weightCategories);
		
	}
	
	public SimpleObject saveCwcTriageInfo(@RequestParam("patientId") Patient patient,
	        @RequestParam("queueId") Integer queueId, @RequestParam("patientEnrollmentDate") Date patientEnrollmentDate,
	        @RequestParam(value = "isEdit", required = false) Boolean isEdit, UiSessionContext session,
	        HttpServletRequest request) {
		PatientQueueService queueService = Context.getService(PatientQueueService.class);
		TriagePatientQueue queue = queueService.getTriagePatientQueueById(queueId);
		try {
			ClinicalForm form = ClinicalForm.generateForm(request, patient, null);
			List<Object> previousVisitsByPatient = Context.getService(MchService.class).findVisitsByPatient(patient, true,
			    true, patientEnrollmentDate);
			int visitTypeId;
			if (previousVisitsByPatient.size() == 0) {
				visitTypeId = EhrMchMetadata.getInitialMCHClinicVisitTypeId();
			} else {
				visitTypeId = EhrMchMetadata.getReturnCwcClinicVisitTypeId();
			}
			Encounter encounter = Context.getService(MchService.class).saveMchEncounter(form,
			    EhrMchMetadata._MchEncounterType.CWC_TRIAGE_ENCOUNTER_TYPE, session.getSessionLocation(), visitTypeId);
			if (request.getParameter("send_for_examination") != null) {
				String visitStatus = queue.getVisitStatus();
				SendForExaminationParser.parse("send_for_examination", request.getParameterValues("send_for_examination"),
				    patient, visitStatus);
			}
			
			if (!isEdit) {
				QueueLogs.logTriagePatient(queue, encounter);
			}
			
			return SimpleObject.create("status", "success", "message", "Triage information has been saved.", "isEdit",
			    isEdit);
		}
		catch (NullPointerException e) {
			log.error(e.getMessage());
			return SimpleObject.create("status", "error", "message", e.getMessage());
		}
		catch (ParseException e) {
			log.error(e.getMessage());
			return SimpleObject.create("status", "error", "message", e.getMessage());
		}
	}
	
	public SimpleObject updatePatientProgram(HttpServletRequest request) {
		
		try {
			String programId = request.getParameter("programId");
			String enrollmentDateYmd = request.getParameter("enrollmentDateYmd");
			String completionDateYmd = request.getParameter("completionDateYmd");
			String outcomeId = request.getParameter("outcomeId");
			Context.getService(MchService.class).updatePatientProgram(Integer.parseInt(programId), enrollmentDateYmd,
			    completionDateYmd, null, Integer.parseInt(outcomeId));
		}
		catch (ParseException e) {
			return SimpleObject.create("status", "error", "message", e.getMessage());
		}
		return SimpleObject.create("status", "success", "message", "Patient Program Updated Successfully");
	}
	
	public List<SimpleObject> getPatientStates(HttpServletRequest request, UiUtils uiUtils) {
		Integer patientProgramId = Integer.parseInt(request.getParameter("patientProgramId"));
		Integer programWorkflowId = Integer.parseInt(request.getParameter("programWorkflowId"));
		List<PatientStateItem> ret = new ArrayList<PatientStateItem>();
		ProgramWorkflowService s = Context.getProgramWorkflowService();
		PatientProgram p = s.getPatientProgram(patientProgramId);
		ProgramWorkflow wf = p.getProgram().getWorkflow(programWorkflowId);
		for (PatientState st : p.statesInWorkflow(wf, false)) {
			ret.add(new PatientStateItem(st));
		}
		return SimpleObject.fromCollection(ret, uiUtils, "patientStateId", "programWorkflowId", "stateName", "workflowName",
		    "startDate", "endDate", "dateCreated", "creator");
	}
	
	public List<SimpleObject> getPossibleNextStates(HttpServletRequest request, UiUtils uiUtils) {
		Integer patientProgramId = Integer.parseInt(request.getParameter("patientProgramId"));
		Integer programWorkflowId = Integer.parseInt(request.getParameter("programWorkflowId"));
		List<ListItem> ret = new ArrayList<ListItem>();
		PatientProgram pp = Context.getProgramWorkflowService().getPatientProgram(patientProgramId);
		ProgramWorkflow pw = pp.getProgram().getWorkflow(programWorkflowId);
		List<ProgramWorkflowState> states = pw.getPossibleNextStates(pp);
		for (ProgramWorkflowState state : states) {
			ListItem li = new ListItem();
			li.setId(state.getProgramWorkflowStateId());
			li.setName(state.getConcept().getName(Context.getLocale(), false).getName());
			ret.add(li);
		}
		return SimpleObject.fromCollection(ret, uiUtils, "id", "name", "description");
	}
	
	public SimpleObject changeToState(HttpServletRequest request, UiUtils ui) {
		Integer patientProgramId = Integer.parseInt(request.getParameter("patientProgramId"));
		Integer programWorkflowId = Integer.parseInt(request.getParameter("programWorkflowId"));
		Integer programWorkflowStateId = Integer.parseInt(request.getParameter("programWorkflowStateId"));
		
		Integer patientId = Integer.parseInt(request.getParameter("patientId"));
		Integer batchNo = null;
		Integer vvmStage = null;
		Integer quantity = null;
		
		if (!request.getParameter("batchNo").equals("")) {
			batchNo = Integer.parseInt(request.getParameter("batchNo"));
			vvmStage = Integer.parseInt(request.getParameter("vvmStage"));
			quantity = Integer.parseInt(request.getParameter("quantity"));
		}
		
		Patient patient = Context.getPatientService().getPatient(patientId);
		
		String onDateDMY = request.getParameter("onDateDMY");
		ProgramWorkflowService s = Context.getProgramWorkflowService();
		PatientProgram pp = s.getPatientProgram(patientProgramId);
		ProgramWorkflow pwf = pp.getProgram().getWorkflow(programWorkflowId);
		ProgramWorkflowState st = pwf.getState(programWorkflowStateId);
		Date onDate = null;
		
		if (onDateDMY != null && onDateDMY.length() > 0) {
			try {
				DateFormat bigEndianDateFormat = new SimpleDateFormat("yyyy-MM-dd");
				onDate = bigEndianDateFormat.parse(onDateDMY);
				pp.transitionToState(st, onDate);
				pp = s.savePatientProgram(pp);
				
				if (batchNo != null) {
					updateImmunizationStorePatientTransaction(patient, batchNo, vvmStage, quantity, pp.getCurrentState(pwf));
				}
			}
			catch (ParseException e) {
				return SimpleObject.create("status", "error", "message", e.getMessage());
			}
			catch (Exception e) {
				return SimpleObject.create("status", "error", "message", e.getMessage());
			}
		}
		
		return SimpleObject.create("status", "success", "message", "State changed Successfully");
	}
	
	private void updateImmunizationStorePatientTransaction(Patient patient, Integer drugBatch, Integer vvmStage,
	        Integer quantity, PatientState state) throws Exception {
		ImmunizationStorePatientTransaction patientTransaction = new ImmunizationStorePatientTransaction();
		ImmunizationStoreDrug storeDrug = immunizationService.getImmunizationStoreDrugById(drugBatch);
		
		Person person = Context.getAuthenticatedUser().getPerson();
		
		patientTransaction.setPatient(patient);
		patientTransaction.setState(state);
		//patientTransaction.setStoreDrug(storeDrug);
		patientTransaction.setVvmStage(vvmStage);
		patientTransaction.setQuantity(quantity);
		patientTransaction.setCreatedOn(new Date());
		patientTransaction.setCreatedBy(person);
		patientTransaction.setRemark("N/A");
		
		patientTransaction = immunizationService.saveImmunizationStorePatientTransaction(patientTransaction);
	}
}
