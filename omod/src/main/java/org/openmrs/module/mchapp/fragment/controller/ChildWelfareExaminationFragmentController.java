package org.openmrs.module.mchapp.fragment.controller;

import org.openmrs.Encounter;
import org.openmrs.Patient;
import org.openmrs.PersonAttribute;
import org.openmrs.PersonAttributeType;
import org.openmrs.api.context.Context;
import org.openmrs.module.appui.UiSessionContext;
import org.openmrs.module.hospitalcore.PatientQueueService;
import org.openmrs.module.hospitalcore.model.Referral;
import org.openmrs.module.hospitalcore.model.ReferralReasons;
import org.openmrs.module.mchapp.model.ImmunizationStoreDrug;
import org.openmrs.module.hospitalcore.model.InventoryDrug;
import org.openmrs.module.hospitalcore.model.OpdPatientQueue;
import org.openmrs.module.ehrinventory.InventoryService;
import org.openmrs.module.mchapp.InternalReferral;
import org.openmrs.module.mchapp.EhrMchMetadata;
import org.openmrs.module.mchapp.api.ImmunizationService;
import org.openmrs.module.mchapp.api.MchService;
import org.openmrs.module.mchapp.api.model.ClinicalForm;
import org.openmrs.module.mchapp.api.parsers.QueueLogs;
import org.openmrs.module.mchapp.api.parsers.SendForExaminationParser;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.fragment.FragmentConfiguration;
import org.openmrs.ui.framework.fragment.FragmentModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestParam;

import javax.servlet.http.HttpServletRequest;
import java.text.ParseException;
import java.util.Date;
import java.util.List;

/**
 * @author Stanslaus Odhiambo Created on 5/30/2016.
 */
public class ChildWelfareExaminationFragmentController {
	
	protected Logger log = LoggerFactory.getLogger(ChildWelfareExaminationFragmentController.class);
	
	public static ImmunizationService immunizationService = Context.getService(ImmunizationService.class);
	
	public void controller(FragmentModel model, FragmentConfiguration config, UiUtils ui) {
		config.require("patientId");
		config.require("queueId");
		String queueId = config.get("queueId").toString();
		String patientID = config.get("patientId").toString();
		Patient patient = Context.getPatientService().getPatient(Integer.parseInt(patientID));
		PersonAttribute pa = patient.getAttribute(EhrMchMetadata.MchAppConstants.CWC_CHILD_COMPLETED_IMMUNIZATION);
		
		model.addAttribute("patient", patient);
		model.addAttribute("patientProfile",
		    PatientProfileGenerator.generatePatientProfile(patient, EhrMchMetadata._MchProgram.CWC_PROGRAM));
		model.addAttribute("patientHistoricalProfile",
		    PatientProfileGenerator.generateHistoricalPatientProfile(patient, EhrMchMetadata._MchProgram.CWC_PROGRAM));
		model.addAttribute("internalReferrals",
		    SimpleObject.fromCollection(Referral.getInternalReferralOptions(), ui, "label", "id", "uuid"));
		model.addAttribute("externalReferrals",
		    SimpleObject.fromCollection(Referral.getExternalReferralOptions(), ui, "label", "id", "uuid"));
		model.addAttribute("referralReasons",
		    SimpleObject.fromCollection(ReferralReasons.getReferralReasonsOptions(), ui, "label", "id", "uuid"));
		model.addAttribute("queueId", queueId);
		
		if (pa == null) {
			model.addAttribute("immunizationStatus", "false");
		} else {
			model.addAttribute("immunizationStatus", pa.getValue());
		}
	}
	
	public SimpleObject saveCwcExaminationInformation(@RequestParam("patientId") Patient patient,
	        @RequestParam("queueId") Integer queueId, UiSessionContext session, HttpServletRequest request) {
		
		OpdPatientQueue patientQueue = Context.getService(PatientQueueService.class).getOpdPatientQueueById(queueId);
		String location = "CWC Exam Room";
		if (patientQueue != null) {
			location = patientQueue.getOpdConceptName();
		}
		try {
			ClinicalForm form = ClinicalForm.generateForm(request, patient, location);
			InternalReferral internalReferral = new InternalReferral();
			Encounter encounter = Context.getService(MchService.class).saveMchEncounter(form,
			    EhrMchMetadata._MchEncounterType.CWC_ENCOUNTER_TYPE, session.getSessionLocation());
			String refferedRoomUuid = request.getParameter("internalRefferal");
			if (refferedRoomUuid != "" && refferedRoomUuid != null && !refferedRoomUuid.equals(0)
			        && !refferedRoomUuid.equals("0")) {
				internalReferral.sendToRefferedRoom(patient, refferedRoomUuid);
			}
			
			//PatientQueueService queueService = Context.getService(PatientQueueService.class);
			//OpdPatientQueue queue = queueService.getOpdPatientQueueById(queueId);
			
			if (request.getParameter("send_for_examination") != null) {
				String visitStatus = patientQueue.getVisitStatus();
				SendForExaminationParser.parse("send_for_examination", request.getParameterValues("send_for_examination"),
				    patient, visitStatus);
			}
			
			System.out.println("CHECKED VALUE:::::" + request.getParameter("child_fully_immunized"));
			
			PersonAttribute pa = patient.getAttribute(EhrMchMetadata.MchAppConstants.CWC_CHILD_COMPLETED_IMMUNIZATION);
			if (pa == null) {
				pa = new PersonAttribute();
				pa.setPerson(patient);
				pa.setAttributeType(new PersonAttributeType(52));
				pa.setCreator(Context.getAuthenticatedUser());
				pa.setDateCreated(new Date());
			}
			
			if (request.getParameter("child_fully_immunized") == null) {
				pa.setValue("false");
			} else {
				if (!pa.getValue().equals("true")) {
					pa.setDateCreated(new Date());
				}
				pa.setValue("true");
			}
			
			patient.addAttribute(pa);
			Context.getPatientService().savePatient(patient);
			
			QueueLogs.logOpdPatient(patientQueue, encounter);
			return SimpleObject.create("status", "success", "message", "Examination information has been saved.");
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
	
	public static SimpleObject getBatchesForSelectedDrug(UiUtils uiUtils, @RequestParam("drgName") String drgName) {
		InventoryDrug drugByName = Context.getService(InventoryService.class).getDrugByName(drgName);
		List<ImmunizationStoreDrug> storeDrugs = null;
		if (drugByName != null) {
			storeDrugs = immunizationService.getAvailableDrugBatches(drugByName.getId());
		}
		
		if (storeDrugs != null && storeDrugs.size() > 0) {
			List<SimpleObject> simpleObjects = SimpleObject.fromCollection(storeDrugs, uiUtils, "id", "batchNo",
			    "currentQuantity", "expiryDate");
			return SimpleObject.create("status", "success", "message", "Found Drugs", "drugs", simpleObjects);
		} else {
			return SimpleObject.create("status", "fail", "message", "No Batch for this Drug");
		}
	}
}
