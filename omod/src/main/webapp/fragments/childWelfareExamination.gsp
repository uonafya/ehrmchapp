<script>
    var drugOrders = new DisplayDrugOrders();
    var selectedInvestigationIds = [];
    var selectedDiagnosisIds = [];
    var investigationQuestionUuid = "1ad6f4a5-13fd-47fc-a975-f5a1aa61f757";
    var provisionalDiagnosisQuestionUuid = "b8bc4c9f-7ccb-4435-bc4e-646d4cf83f0a";
    var finalDiagnosisQuestionUuid = "7033ef37-461c-4953-a757-34722b6d9e38"
    var diagnosisQuestionUuid = "";
    var NavigatorController;

    var examinationArray = [];
    var investigationArray = [];
    var diagnosisArray = [];

    var emrMessages = {};
    emrMessages["numericRangeHigh"] = "value should be less than {0}";
    emrMessages["numericRangeLow"] = "value should be more than {0}";
    emrMessages["requiredField"] = "Mandatory Field. Kindly provide details";
    emrMessages["numberField"] = "Value not a number";

    var currentWorkflowBeingEdited;
    var patientProgramForWorkflowEdited;

    var outcomeId;

    jq(function () {
        function SubmitInformation() {
            var data = jq("form#cwcExaminationsForm").serialize();
            data = data + "&" + objectToQueryString.convert(drugOrders["drug_orders"]);

            jq.post('${ui.actionLink("mchapp", "childWelfareExamination", "saveCwcExaminationInformation")}',
                    data,
                    function (data) {
                        if (data.status === "success") {
                            window.location = "${ui.pageLink("patientqueueapp", "mchClinicQueue")}"
                        } else if (data.status === "error") {
                            jq().toastmessage('showErrorToast', data.message);
                        }
                    },
                    "json"
            );
        }

        function handleExitProgram(programId, enrollmentDateYmd, completionDateYmd, outcomeId) {
            var updateData = {
                programId: programId,
                enrollmentDateYmd: enrollmentDateYmd,
                completionDateYmd: completionDateYmd,
                outcomeId: outcomeId
            }
            jq.getJSON('${ ui.actionLink("mchapp", "cwcTriage", "updatePatientProgram") }', updateData)
				.success(function (data) {
					SubmitInformation();
				}).error(function (xhr, status, err) {
					jq().toastmessage('showErrorToast', "AJAX error!" + err);
				}
            );
        }

        //submit data
        jq("#antenatalExaminationSubmitButton").on("click", function (event) {
            event.preventDefault();

            if (jq('#exitPatientFromProgramme:checked').length > 0) {
                exitcwcdialog.show();
            } else {
                SubmitInformation();
            }
        });

        var exitcwcdialog = emr.setupConfirmationDialog({
            dialogOpts: {
                overlayClose: false,
                close: true
            },
            selector: '#exitCwcDialog',
            actions: {
                confirm: function () {
                    var endDate = jq("#complete-date-field").val();
                    outcomeId = jq("#programOutcome").val();
                    var startDate = "${patientProgram.dateEnrolled}";

                    if (outcomeId == '' || outcomeId == "0") {
                        alert("Outcome Required");
                        return;
                    }
                    //&& startDate > endDate run test to ensure end date is not earlier than start start date

                    else if (!isEmpty(startDate) && !isEmpty(endDate)) {
                        var result = handleExitProgram(${patientProgram.patientProgramId}, "${patientProgram.dateEnrolled}",
                                endDate, outcomeId);

                    } else {
                        alert("invalid end date");
                        return;
                    }
                    exitcwcdialog.close();
                },
                cancel: function () {
                    exitcwcdialog.close();
                }
            }
        });

        var vaccinationDialog = emr.setupConfirmationDialog({
            dialogOpts: {
                overlayClose: false,
                close: true
            },
            selector: '#vaccinations-dialog',
            actions: {
                confirm: function () {
                    var idnt 		= jq('#vaccine-idnt').val();
                    var prog 		= jq('#vaccine-prog').val();
                    var name 		= jq('#vaccine-name').val();
                    var state 		= jq('#vaccine-state').val();
                    var batchNo 	= jq('#vaccine-batch').val();
                    var vvmStage 	= jq('#vaccine-stage').val();
                    var quantity 	= jq('#vaccine-quantity').val();
					
                    if (state == 0) {
                        jq().toastmessage('showErrorToast', "Kindly select a vaccine state!");
                        return false;
                    }
					
					if (batchNo == 0) {
                        jq().toastmessage('showErrorToast', "Kindly select a vaccine Batch!");
                        return false;
                    }
					
					if (vvmStage == 0) {
                        jq().toastmessage('showErrorToast', "Kindly select a vaccine VVM Stage!");
                        return false;
                    }
					
					if (!jq.isNumeric(quantity)) {
                        jq().toastmessage('showErrorToast', "Invalid Vaccine Quantity!");
                        return false;
                    }

                    var stateData = {
                        patientProgramId: prog,
                        programWorkflowId: idnt,
                        programWorkflowStateId: jq('#vaccine-state').val(),
                        onDateDMY: jq('#vaccine-date-field').val(),
                        batchNo: batchNo,
                        vvmStage: vvmStage,
                        quantity: quantity,
                        patientId:${patient?.patientId}
                    }

                    jq.getJSON('${ ui.actionLink("mchapp", "cwcTriage", "changeToState") }', stateData)
						.success(function (data) {
							jq().toastmessage('showNoticeToast', data.message);

							showEditWorkflowPopup(name, prog, idnt);

							jq('#state_name_' + idnt).text(jq('#vaccine-state option:selected').text());
							jq('#state_date_' + idnt).text(moment(jq('#vaccine-date-field').val()).fromNow());

							jq('#main-show-' + idnt).show();
							jq('#no-show-' + idnt).hide();

							jq('#immunizations-set').val('SET');

							vaccinationDialog.close();
							return false;

						}).error(function (xhr, status, err) {
							jq().toastmessage('showErrorToast', "AJAX error!" + err);
							return false;
						}
					);

                },
                cancel: function () {
                    vaccinationDialog.close();
                    return false;
                }
            }
        });
		
		jq('#vaccine-state').change(function(){
			if (jq('#vaccine-name').val() == 'VITAMIN A' && jq('#vaccine-state').val() != 0){
				checkVitaminABatchesAvailability();			
			}
		});

        jq('.update-vaccine a').click(function () {
            var idnt = jq(this).data('idnt');
            var name = jq(this).data('name');
            var prog = jq(this).data('prog');
			
            jq('#vaccine-idnt').val(idnt);
            jq('#vaccine-name').val(name);
            jq('#vaccine-prog').val(prog);

            jq('#vaccine-state').html(jq('#changeToState_' + idnt).html());

            checkBatchAvailability(name);
            vaccinationDialog.show();
        });

        jq('.chevron').click(function () {
            var idnt = jq(this).data('idnt');
            var name = jq(this).data('name');
            var prog = jq(this).data('prog');

            if (jq(this).hasClass('icon-chevron-right')) {
                jq(this).removeClass('icon-chevron-right');
                jq(this).addClass('icon-chevron-down');

                showEditWorkflowPopup(name, prog, idnt);
            }
            else {
                jq(this).removeClass('icon-chevron-down');
                jq(this).addClass('icon-chevron-right');

                jq("#currentStateDetails_" + idnt).show();
                jq("#currentStateVaccine_" + idnt).hide();
            }
        });

        NavigatorController = new KeyboardController(jq('#cwcExaminationsForm'));
        ko.applyBindings(drugOrders, jq(".drug-table")[0]);

        var patientProfile = JSON.parse('${patientProfile}');
        var patientHistoricalProfile = JSON.parse('${patientHistoricalProfile}');

        if (patientProfile.details.length > 0) {
            var patientProfileTemplate = _.template(jq("#patient-profile-template").html());
            jq(".patient-profile").append(patientProfileTemplate(patientProfile));
        }

        var examinations = [];

        var adddrugdialog = emr.setupConfirmationDialog({
            dialogOpts: {
                overlayClose: false,
                close: true
            },
            selector: '#prescription-dialog',
            actions: {
                confirm: function () {
                    if (!drugDialogVerified()) {
                        jq().toastmessage('showErrorToast', 'Ensure fields marked in red have been properly filled before you continue')
                        return false;
                    }

                    addDrug();
                    jq("#drugForm")[0].reset();
                    jq('select option[value!="0"]', '#drugForm').remove();
                    adddrugdialog.close();
                },
                cancel: function () {
                    jq("#drugForm")[0].reset();
                    jq('select option[value!="0"]', '#drugForm').remove();
                    adddrugdialog.close();
                }
            }
        });

        jq("#availableReferral").on("change", function () {
            selectReferrals(jq("#availableReferral").val());
        });

        jq("#addDrugsButton").on("click", function (e) {
            adddrugdialog.show();
        });

        jq(".drug-name").on("focus.autocomplete", function () {
            var selectedInput = this;
            jq(this).autocomplete({
                minLength: 3,
                source: function (request, response) {
                    jq.getJSON('${ ui.actionLink("patientdashboardapp", "ClinicalNotes", "getDrugs") }',
                            {
                                q: request.term
                            }
                    ).success(function (data) {
                                var results = [];
                                for (var i in data) {
                                    var result = {label: data[i].name, value: data[i].id};
                                    results.push(result);
                                }
                                response(results);
                            });
                },
                select: function (event, ui) {
                    event.preventDefault();
                    jq(selectedInput).val(ui.item.label);
                    jq(selectedInput).data("drug-id", ui.item.value);
                },
                change: function (event, ui) {
                    event.preventDefault();
                    jq.getJSON('${ ui.actionLink("patientdashboardapp", "ClinicalNotes", "getFormulationByDrugName") }',
                            {
                                "drugName": ui.item.label
                            }
                    ).success(function (data) {
                                var formulations = jq.map(data, function (formulation) {
                                    jq('#formulationsSelect').append(jq('<option>').attr('value', formulation.id).text(formulation.name + ':' + formulation.dozage));
                                });
                            });

                    jq.getJSON('${ ui.actionLink("patientdashboardapp", "ClinicalNotes", "getFrequencies") }').success(function (data) {
                        var frequencies = jq.map(data, function (frequency) {
                            jq('#frequencysSelect').append(jq('<option>').attr('value', frequency.uuid).text(frequency.name));
                        });
                    });

                    jq.getJSON('${ ui.actionLink("patientdashboardapp", "ClinicalNotes", "getDrugUnit") }').success(function (data) {
                        var durgunits = jq.map(data, function (drugUnit) {
                            jq('#drugUnitsSelect').append(jq('<option>').val(drugUnit.id).text(drugUnit.label));
                        });
                    });
                },
                open: function () {
                    jq(this).removeClass("ui-corner-all").addClass("ui-corner-top");
                },
                close: function () {
                    jq(this).removeClass("ui-corner-top").addClass("ui-corner-all");
                }
            });
        });

        //examinations autocomplete functionality
        jq("#searchExaminations").autocomplete({
            minLength: 0,
            source: function (request, response) {
                jq.getJSON('${ ui.actionLink("mchapp", "examinationFilter", "searchFor") }', {
                    findingQuery: request.term
                }).success(function (data) {
                    examinations = data;
                    response(data);
                });
            },
            select: function (event, ui) {
                var examination = _.find(examinations, function (exam) {
                    return exam.value === ui.item.value;
                });

                if (!examinationArray.find(function (exam) {
                            return exam.value == examination.value;
                        })) {
                    var provisionalDiagnosisQuestionUuid = "b8bc4c9f-7ccb-4435-bc4e-646d4cf83f0a";

                    var examTemplate = _.template(jq("#examination-detail-template").html());
                    jq("#exams-holder").append(examTemplate(examination));
                    jq('#exams-set').val('SET');
                    jq('#task-exams').show();

                    examinationArray.push(examination);
                    examinationSummary();
                }
                else {
                    jq().toastmessage('showErrorToast', 'The test ' + examination.label + ' has already been added.');
                }

                jq(this).val('');
                return false;
            }
        });

        jq("#exams-holder").on("click", "#selectedExamination", function () {
            var uid = jq(this).data('uid');
            examinationArray = examinationArray.filter(function (examination) {
                return examination.value != uid;
            });

            examinationSummary();
            jq(this).parent("div").remove();

            if (jq("#examination-detail-div").length == 0) {
                jq('#exams-set').val('');
                jq('#task-exams').hide();
            }
        });

        jq("#7cdc2d69-31b9-4592-9a3f-4bc167d5780b").on('change', function () {
            if (jq("#7cdc2d69-31b9-4592-9a3f-4bc167d5780b").is(':checked')) {
                jq('#specifyOther').show();
            } else {
                jq('#specifyOther').hide();
            }
        });

        function examinationSummary() {
            if (examinationArray.length == 0) {
                jq('#summaryTable tr:eq(1) td:eq(1)').text('N/A');
            }
            else {
                var exams = '';
                examinationArray.forEach(function (examination) {
                    exams += examination.label + '<br/>'
                });
                jq('#summaryTable tr:eq(1) td:eq(1)').html(exams);
            }
        }

        //select whether diagnosis is provisional or final
        jq("#provisional-diagnosis").on("click", function () {
            diagnosisQuestionUuid = provisionalDiagnosisQuestionUuid;
        })
        jq("#final-diagnosis").on("click", function () {
            diagnosisQuestionUuid = finalDiagnosisQuestionUuid;
        })

        //Diagnosis autocomplete functionality
        jq("#diagnoses").autocomplete({
            source: function (request, response) {
                jq.getJSON('${ ui.actionLink("patientdashboardapp", "ClinicalNotes", "getDiagnosis") }',
                        {
                            q: request.term
                        }
                ).success(function (data) {
                            var results = [];
                            for (var i in data) {
                                var result = {label: data[i].name, value: data[i].uuid};
                                results.push(result);
                            }
                            response(results);
                        });
            },
            minLength: 3,
            select: function (event, ui) {
                if (!selectedDiagnosisIds.includes(ui.item.value)) {
                    var diagnosis = {};
                    diagnosis.label = ui.item.label;
                    diagnosis.questionUuid = diagnosisQuestionUuid;
                    diagnosis.uuid = ui.item.value;
                    diagnosis.value = ui.item.value;

                    diagnosisArray.push(ui.item);
                    diagnosisSummary();
                    var diagnosisTemplate = _.template(jq("#diagnosis-template").html());
                    jq("#diagnosis-holder").append(diagnosisTemplate(diagnosis));
                    jq('#diagnosis-set').val('SET');
                    jq('#task-diagnosis').show();

                    selectedDiagnosisIds.push(ui.item.value);
                } else {
                    jq().toastmessage('showErrorToast', ui.item.label + ' has already been added.');
                }
                jq(this).val('');
                return false;
            },
            open: function () {
                jq(this).removeClass("ui-corner-all").addClass("ui-corner-top");
            },
            close: function () {
                jq(this).removeClass("ui-corner-top").addClass("ui-corner-all");
            }
        });

        function diagnosisSummary() {
            if (diagnosisArray.length == 0) {
                jq('#summaryTable tr:eq(3) td:eq(1)').text('N/A');
            }
            else {
                var diagnoses = '';
                diagnosisArray.forEach(function (diagnosis) {
                    diagnoses += diagnosis.label + '<br/>'
                });
                jq('#summaryTable tr:eq(3) td:eq(1)').html(diagnoses);
            }
        }

        jq("#diagnosis-holder").on("click", ".icon-remove", function () {
            var diagnosisId = jq(this).parents('div.diagnosis').find('input[type="hidden"]').attr("value");
            selectedDiagnosisIds.splice(selectedDiagnosisIds.indexOf(diagnosisId));

            diagnosisArray = diagnosisArray.filter(function (diagnosis) {
                return diagnosis.value != diagnosisId;
            });

            diagnosisSummary();

            jq(this).parents('div.diagnosis').remove();
            if (jq(".diagnosis").length == 0) {
                jq('#diagnosis-set').val('');
                jq('#task-diagnosis').hide();
            }
        });

        //investigations autocomplete functionality
        jq("#investigation").autocomplete({
            source: function (request, response) {
                jq.getJSON('${ ui.actionLink("patientdashboardapp", "ClinicalNotes", "getInvestigations") }',
                        {
                            q: request.term
                        }
                ).success(function (data) {
                            var results = [];
                            for (var i in data) {
                                var result = {label: data[i].name, value: data[i].uuid};
                                results.push(result);
                            }
                            response(results);
                        });
            },
            minLength: 3,
            select: function (event, ui) {
                if (!selectedInvestigationIds.includes(ui.item.value)) {
                    var investigation = {};
                    investigation.label = ui.item.label;
                    investigation.questionUuid = investigationQuestionUuid;
                    investigation.uuid = ui.item.value;
                    investigation.value = ui.item.value;

                    investigationArray.push(ui.item);
                    investigationSummary();
                    var investigationTemplate = _.template(jq("#investigation-template").html());
                    jq("#investigations-holder").append(investigationTemplate(investigation));
                    jq('#investigations-set').val('SET');
                    jq('#task-investigations').show();

                    selectedInvestigationIds.push(ui.item.value);
                } else {
                    jq().toastmessage('showErrorToast', ui.item.label + ' has already been added.');
                }
                jq(this).val('');
                return false;
            },
            open: function () {
                jq(this).removeClass("ui-corner-all").addClass("ui-corner-top");
            },
            close: function () {
                jq(this).removeClass("ui-corner-top").addClass("ui-corner-all");
            }
        });

        jq("#investigations-holder").on("click", ".icon-remove", function () {
            var investigationId = parseInt(jq(this).parents('div.investigation').find('input[type="hidden"]').attr("value"));
            selectedInvestigationIds.splice(selectedInvestigationIds.indexOf(investigationId));

            investigationArray = investigationArray.filter(function (investigation) {
                return investigation.value != investigationId;
            });

            investigationSummary();

            jq(this).parents('div.investigation').remove();
            if (jq(".investigation").length == 0) {
                jq('#investigations-set').val('');
                jq('#task-investigations').hide();
            }
        });

        function investigationSummary() {
            if (investigationArray.length == 0) {
                jq('#summaryTable tr:eq(4) td:eq(1)').text('N/A');
            }
            else {
                var exams = '';
                investigationArray.forEach(function (investigation) {
                    exams += investigation.label + '<br/>'
                });
                jq('#summaryTable tr:eq(4) td:eq(1)').html(exams);
            }
        }

        jq('#specific-disability, .feeding-info input').change(function () {
            jq('#feeding-info-set').val('SET');

            var output = '';
            if (jq("input[name='concept.a082375c-bfe4-4395-9ed5-d58e9ab0edd3']:checked").val() == '4536f271-5430-4345-b5f7-37ca4cfe1553') {
                output += '&#9745; Exclusive Breastfeeding (0-6 months)<br/>';
            }

            if (jq("input[name='concept.42197783-8b24-49b0-b290-cbb368fa0113']:checked").val() == '4536f271-5430-4345-b5f7-37ca4cfe1553') {
                output += '&#9745; Counselled on Nutrition?<br/>';
            }

            if (jq("input[name='concept.8a3c420e-b4ff-4710-81fd-90c7bfa6de72']:checked").val() == '4536f271-5430-4345-b5f7-37ca4cfe1553') {
                output += '&#9745; Counselled on HIV<br/>';
            }

            if (jq("input[name='concept.d311a2d5-8af3-4161-9df4-35f26b04dded']:checked").val() == '4536f271-5430-4345-b5f7-37ca4cfe1553') {
                output += '&#9745; Disability ' + jq('#specific-disability').val();
                jq('#specific-disability').show();
            }
            else {
                jq('#specific-disability').hide();
                jq('#specific-disability').val('');
            }

            if (output == '') {
                output = 'N/A';
            }

            jq('#summaryTable tr:eq(5) td:eq(1)').html(output);
        });

        jq('.treatment-info input').change(function () {
            jq('#treatment-info-set').val('SET');
            var output = '';

            if (!jq("input[name='concept.160428AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA']:checked").val()) {
                output += 'RECEIVED LLITN: results not provided' + '<br/>';
            }
            else {
                output += 'RECEIVED LLITN: ' + jq("input[name='concept.160428AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA']:checked").data('value') + '<br/>';
            }

            if (!jq("input[name='concept.159922AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA']:checked").val()) {
                output += 'Dewormed: results not provided' + '<br/>';
            }
            else {
                output += 'Dewormed: ' + jq("input[name='concept.159922AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA']:checked").data('value') + '<br/>';
            }
            if (!jq("input[name='concept.c1346a48-9777-428f-a908-e8bff24e4e37']:checked").val()) {
                output += 'Vitamin A Supplementation (6-59 months): results not provided' + '<br/>';
            }
            else {
                output += 'Vitamin A Supplementation (6-59 months): ' + jq("input[name='concept.c1346a48-9777-428f-a908-e8bff24e4e37']:checked").data('value') + '<br/>';
            }

            if (!jq("input[name='concept.534705aa-8857-4e70-9b08-b363fb3ce677']:checked").val()) {
                output += 'Supplemented with MNP (6-23 months): results not provided' + '<br/>';
            }
            else {
                output += 'Supplemented with MNP (6-23 months): ' + jq("input[name='concept.534705aa-8857-4e70-9b08-b363fb3ce677']:checked").data('value') + '<br/>';
            }
            jq('#summaryTable tr:eq(6) td:eq(1)').html(output);
        });

        jq('#cwcFollowUp input').change(function () {
            jq('#referral-set').val('SET');
            var output = '';

            if (jq('input[value="d87a8764-8e2d-4297-b49a-acbc1210109e"]:checked').length > 0) {
                output += '&#9745; NUTRITIONAL MARASMUS<br/>';
            }

            if (jq('input[value="6eac3451-66b6-4057-b765-1b47e6ecff6b"]:checked').length > 0) {
                output += '&#9745; 	KWASHIORKOR<br/>';
            }

            if (jq('input[value="cdc6042c-7237-4150-87c4-12152c7e2542"]:checked').length > 0) {
                output += '&#9745; 	MALNUTRITION<br/>';
            }

            if (jq('input[value="7cdc2d69-31b9-4592-9a3f-4bc167d5780b"]:checked').length > 0) {
                output += '&#9745; 	OTHER ' + jq('#specifyOther').val();
            }

            if (output == '') {
                output = 'N/A';
            }

            jq('#summaryTable tr:eq(7) td:eq(1)').html(output);
        });

        jq('#availableReferral, #next-visit-date-display').change(function () {
            var output = '';

            if (jq('#availableReferral').val() == "1") {
                output += 'Internal Referral<br/>';
                jq('#referral-set').val('SET');
            }
            else if (jq('#availableReferral').val() == "2") {
                output += 'External Referral<br/>';
                jq('#referral-set').val('SET');
            }

            if (jq('#next-visit-date-display').val() != '') {
                output += 'Next Visit: ' + jq('#next-visit-date-display').val();
                jq('#referral-set').val('SET');
            }

            if (output == '') {
                jq('#referral-set').val('');
                output = 'N/A';
            }

            jq('#summaryTable tr:eq(8) td:eq(1)').html(output);
        });

        jq('#referralReason').change(function () {
            if (jq(this).val() == "8") {
                jq('#externalRefferalSpc').show();
            }
            else {
                jq('#externalRefferalSpc').hide();
            }
        }).change();


    });//End of Document Ready

    function refreshPage() {
        window.location.reload();
    }

    function isEmpty(o) {
        return o == null || o == '';
    }

    function showEditWorkflowPopup(wfName, patientProgramId, programWorkflowId) {
        jq("#currentStateDetails_" + programWorkflowId).hide();
        var params = {
            patientProgramId: patientProgramId,
            programWorkflowId: programWorkflowId
        }
        jq.getJSON('${ ui.actionLink("mchapp", "cwcTriage", "getPossibleNextStates") }', params)
                .success(function (data) {
                    //load drop down
                }).error(function (xhr, status, err) {
                    jq().toastmessage('showErrorToast', "AJAX error!" + err);
                });
        jq.getJSON('${ ui.actionLink("mchapp", "cwcTriage", "getPatientStates") }', params)
                .success(function (data) {
                    //load list of previous vaccines
                    var tableId = "workflowTable_" + programWorkflowId;
                    jq('#' + tableId + ' > tbody > tr').remove();
                    var tbody = jq('#' + tableId + ' > tbody');

                    if (data.length == 0) {
                        tbody.append('<tr align="center"><td colspan="6">No Previous Vaccinations found for ' + wfName + '</td></tr>');
                    } else {
                        for (index in data) {
                            var item = data[index];
                            var row = '<tr>';
                            row += '<td>' + (parseInt(index) + 1) + '</td>';
                            row += '<td>' + item.stateName + '</td>';
                            row += '<td>' + moment(item.startDate, 'DD.MMM.YYYY').format('DD/MM/YYYY') + '</td>';
                            row += '<td>' + getReadableAge('${patient?.birthdate}', moment(item.startDate, 'DD.MMM.YYYY').format('DD/MM/YYYY')) + '</td>';
                            row += '<td>' + moment(item.dateCreated, 'DD.MMM.YYYY').format('DD/MM/YYYY') + '</td>';
                            row += '<td>' + item.creator + '</td>';
                            row += '</tr>';
                            tbody.append(row);
                        }

                    }

                }).error(function (xhr, status, err) {
                    jq().toastmessage('showErrorToast', "AJAX error!" + err);
                });

        jq("#currentStateVaccine_" + programWorkflowId).show();
        currentWorkflowBeingEdited = programWorkflowId;
        patientProgramForWorkflowEdited = patientProgramId;
    }

    function handleChangeWorkflowState(c) {
        var stateId = jq("#changeToState_" + c).val();
        var onDate = jq("#datepicker_" + c).val()

        if (stateId == 0) {
            jq().toastmessage('showErrorToast', "Select State!");
            return;
        } else if (isEmpty(onDate)) {
            jq().toastmessage('showErrorToast', "Select Date!");
            return;
        } else {
            jq().toastmessage('showNoticeToast', "Saving State...!");
            processHandleChangeWorkflowState(stateId, onDate);
        }

    }

    function processHandleChangeWorkflowState(stateId, onDateDMY) {
        var ppId = patientProgramForWorkflowEdited;
        var wfId = currentWorkflowBeingEdited;

        var stateData = {
            patientProgramId: ppId,
            programWorkflowId: wfId,
            programWorkflowStateId: stateId,
            onDateDMY: onDateDMY
        }

        jq.getJSON('${ ui.actionLink("mchapp", "cwcTriage", "changeToState") }', stateData)
                .success(function (data) {
                    jq().toastmessage('showNoticeToast', data.message);
                    return data.status;
                }).error(function (xhr, status, err) {
                    jq().toastmessage('showErrorToast', "AJAX error!" + err);
                });
    }

    function hideLayer(divId) {
        jq("#currentStateVaccine_" + divId).hide();
        jq("#currentStateDetails_" + divId).show();
        refreshPage();
    }

    function selectReferrals(selectedReferral) {
        if (selectedReferral == 1) {
            jq("#internalRefferalDiv").show();
            jq("#externalRefferalDiv").hide();
            jq("#externalRefferalFac").hide();
            jq("#externalRefferalRsn").hide();
            jq("#externalRefferalSpc").hide();
            jq("#externalRefferalCom").hide();
        } else if (selectedReferral == 2) {
            jq("#internalRefferalDiv").hide();
            jq("#externalRefferalDiv").show();
            jq("#externalRefferalFac").show();
            jq("#externalRefferalRsn").show();
            jq("#externalRefferalCom").show();

            jq('#referralReason').change();
        }
        else {
            jq("#internalRefferalDiv").hide();
            jq("#externalRefferalDiv").hide();
            jq("#externalRefferalFac").hide();
            jq("#externalRefferalRsn").hide();
            jq("#externalRefferalSpc").hide();
            jq("#externalRefferalCom").hide();
        }
    }

    function addDrug() {
        var addDrugsTableBody = jq("#addDrugsTable tbody");
        var drugName = jq("#drugName").val();
        var drugDosage = jq("#drugDosage").val();
        var dosageUnit = {};
        dosageUnit.id = jq("#drugUnitsSelect option:selected").val();
        dosageUnit.text = jq("#drugUnitsSelect option:selected").text();
        var formulation = {};
        formulation.id = jq("#formulationsSelect option:selected").val();
        formulation.text = jq("#formulationsSelect option:selected").text();
        var frequency = {};
        frequency.id = jq("#frequencysSelect option:selected").val();
        frequency.text = jq("#frequencysSelect option:selected").text();
        var numberOfDays = jq("#numberOfDays").val();
        var comment = jq("#comment").val();

        var drugId = jq("#drugName").data("drugId");
        var drugOrderDetail = new DrugOrder(drugId, drugName, drugDosage,
                dosageUnit, formulation, frequency,
                numberOfDays, comment);

        drugOrders.addDrugOrder(drugId, drugOrderDetail);
    }


    function checkBatchAvailability(drgName) {
		if (drgName == 'VITAMIN A'){
			return false;		
		}
		
        var requestData = {
            drgName: drgName
        }
        jq.getJSON('${ ui.actionLink("mchapp", "childWelfareExamination", "getBatchesForSelectedDrug") }', requestData)
			.success(function (data) {
				var options = jq("#vaccine-batch");
				options.empty();
				options.append(jq("<option />").val("0").text("Select Batch"));
				
				if (data.status === "fail") {
					jq().toastmessage('showErrorToast', data.message);
					return false;
				}

				jq.each(data.drugs, function (i, item) {
					options.append(jq("<option />").val(item.id).text(item.batchNo));
				});
			}).error(function (xhr, status, err) {
				jq().toastmessage('showErrorToast', "AJAX error!" + err);
			}
        );
    }
	
	function checkVitaminABatchesAvailability() {		
        var requestData = {
            drgName: jq('#vaccine-state :selected').text().split("(")[0].trim()
        }
        jq.getJSON('${ ui.actionLink("mchapp", "childWelfareExamination", "getBatchesForSelectedDrug") }', requestData)
			.success(function (data) {
				var options = jq("#vaccine-batch");
				options.empty();
				options.append(jq("<option />").val("0").text("Select Batch"));
				
				if (data.status === "fail") {
					jq().toastmessage('showErrorToast', data.message);
					return false;
				}

				jq.each(data.drugs, function (i, item) {
					options.append(jq("<option />").val(item.id).text(item.batchNo));
				});
			}).error(function (xhr, status, err) {
				jq().toastmessage('showErrorToast', "AJAX error!" + err);
			}
        );
    }
</script>

<style>
.col1, .col2, .col3, .col4, .col5, .col6, .col7, .col8, .col9, .col10, .col11, .col12 {
    color: #555;
    text-align: left;
}

#exams-holder input[type="radio"] {
    float: none;
}

.investigation .selecticon,
#examination-detail-div .selecticon {
    color: #f00;
    cursor: pointer;
    float: right;
    margin: 7px 7px 0 0;
}

.tasks {
    margin: 10px 0 0;
    padding-bottom: 10px;
    width: 100%;
}

.investigation {
    border-top: 1px dotted #ccc;
    margin: 0 0 5px;
}

.investigation:first-child {
    border-top: 1px none #ccc;
    margin: 5px 0 5px;
}

#examination-detail-div {
    border-top: 1px dotted #ccc;
    margin: 0 0 10px;
}

#examination-detail-div:first-child {
    border-top: 1px none #ccc;
    margin: 10px 0 10px;
}

section {
    min-height: 300px;
}

.dialog-content input[type="text"], .dialog-content select {
    display: inline-block !important;
    width: 238px !important;
}

.simple-form-ui section fieldset select:focus, .simple-form-ui section fieldset input:focus, .simple-form-ui section #confirmationQuestion select:focus, .simple-form-ui section #confirmationQuestion input:focus, .simple-form-ui #confirmation fieldset select:focus, .simple-form-ui #confirmation fieldset input:focus, .simple-form-ui #confirmation #confirmationQuestion select:focus, .simple-form-ui #confirmation #confirmationQuestion input:focus, .simple-form-ui form section fieldset select:focus, .simple-form-ui form section fieldset input:focus, .simple-form-ui form section #confirmationQuestion select:focus, .simple-form-ui form section #confirmationQuestion input:focus, .simple-form-ui form #confirmation fieldset select:focus, .simple-form-ui form #confirmation fieldset input:focus, .simple-form-ui form #confirmation #confirmationQuestion select:focus, .simple-form-ui form #confirmation #confirmationQuestion input:focus {
    outline: 1px none #f00
}

.patient-profile {
    border: 1px solid #eee;
    margin: 5px 0;
    padding: 7px 12px;
}

.thirty-three-perc {
    border-left: 1px solid #363463;
    display: inline-block;
    float: left;
    font-size: 15px !important;
    padding-left: 1%;
    width: 32%;
}

.thirty-three-perc small {
    float: left;
    font-size: 85% !important;
    min-width: 80px;
    margin-right: 4px;
}

.thirty-three-perc span {
    color: #555;
    float: left;
    font-size: 90%;
}

table[id*='workflowTable_'] th:first-child {
    width: 5px;
}

table[id*='workflowTable_'] th:nth-child(3),
table[id*='workflowTable_'] th:nth-child(4) {
    width: 80px;
}

.update-vaccine {
    float: right;
}

.update-vaccine a {
    cursor: pointer;
}

.update-vaccine a:hover {
    text-decoration: none;
}

.simple-form-ui section, .simple-form-ui #confirmation, .simple-form-ui form section, .simple-form-ui form #confirmation {
    background: #fff none repeat scroll 0 0;
}

.chevron {
    color: #4a80ff !important;
    cursor: pointer;
    font-size: 100% !important;
    margin: 5px;
    text-decoration: none;
}

#next-visit-date-wrapper {
    padding-left: 10px;
}

#next-visit-date label {
    display: none;
}

#next-visit-date input {
    width: 95% !important;
}

.important {
    color: #f00 !important;
}

</style>

<script id="examination-detail-template" type="text/template">
<div id="examination-detail-div">
    <span id="selectedExamination" data-uid="{{=value}}" class="icon-remove selecticon"></span>
    <label style="margin-top: 0px; width: 95%;">{{-label}}</label>
    <input type="{{-text_type}}" name="{{-text_name}}" style="margin-left: 10px ! important; width: 95% ! important;"
           placeholder="SPECIFY VALUE FOR {{-label}}"/>
    <br/>

    {{ _.each(answers, function(answer, index) { }}
    <label style="width: 95%; cursor: pointer;">
        <input type="radio" name="concept.{{=value}}" value="{{=answer.uuid}}">
        {{=answer.display}}
    </label>
    <br/>
    {{ }); }}
</div>
</script>

<script id="diagnosis-template" type="text/template">
<div class="investigation diagnosis">
    <span class="icon-remove selecticon"></span>
    <label style="margin-top: 2px; width: 95%;">{{=label}}
        <input type="hidden" name="concept.{{=questionUuid}}" value="{{=uuid}}"/>
    </label>
</div>
</script>

<script id="investigation-template" type="text/template">
<div class="investigation">
    <span class="icon-remove selecticon"></span>
    <label style="margin-top: 2px; width: 95%;">{{=label}}
        <input type="hidden" name="test_order.{{=questionUuid}}" value="{{=uuid}}"/>
    </label>
</div>
</script>

<% if (opdConcept.equalsIgnoreCase("MCH CLINIC")) { %>
<form method="post" id="cwcExaminationsForm" class="simple-form-ui">
    <input type="hidden" name="patientId" value="${patient?.patientId}">
    <input type="hidden" name="queueId" value="${queueId}">

    <section>

        <span class="title">Clinical Notes</span>

        <fieldset class="no-confirmation">
            <legend>Symptoms</legend>

            <div style="padding: 0 4px">
                <label for="symptom" class="label">Symptoms <span class="important"></span></label>
                <input type="text" id="symptom" name="symptom" placeholder="Add Symptoms"/>
                <field>
                    <input type="hidden" id="symptoms-set" class=""/>
                    <span id="symptoms-lbl" class="field-error" style="display: none"></span>
                </field>
            </div>

            <div class="tasks" id="task-symptom" style="display:none;">
                <header class="tasks-header">
                    <span id="title-symptom" class="tasks-title">PATIENT'S SYMPTOMS</span>
                    <a class="tasks-lists"></a>
                </header>

                <div id="symptoms-holder"></div>
            </div>
        </fieldset>

        <fieldset class="no-confirmation">
            <legend>Examinations</legend>

            <div style="padding: 0 4px">
                <label for="searchExaminations" class="label title-label">Examinations <span class="important"></span>
                </label>
                <input type="text" id="searchExaminations" name="" value="" placeholder="Add Examination"/>
                <field>
                    <input type="hidden" id="exams-set" class=""/>
                    <span id="exams-lbl" class="field-error" style="display: none"></span>
                </field>

                <div class="tasks" id="task-exams" style="display:none;">
                    <header class="tasks-header">
                        <span id="title-symptom" class="tasks-title">PATIENT'S EXAMINATIONS</span>
                        <a class="tasks-lists"></a>
                    </header>

                    <div id="exams-holder"></div>
                </div>
            </div>
        </fieldset>

        <fieldset class="no-confirmation">
            <legend>Diagnosis</legend>
            <label for="diagnoses" class="label title-label">Diagnosis <span class="important"></span></label>

            <div class="tasks-list">
                <div class="left">
                    <label id="ts01" class="tasks-list-item" for="provisional-diagnosis">

                        <input type="radio" name="diagnosis_type" id="provisional-diagnosis" value="true"
                               data-bind="checked: diagnosisProvisional" class="tasks-list-cb focused"/>

                        <span class="tasks-list-mark"></span>
                        <span class="tasks-list-desc">Provisional</span>
                    </label>
                </div>

                <div class="left">
                    <label class="tasks-list-item" for="final-diagnosis">
                        <input type="radio" name="diagnosis_type" id="final-diagnosis" value="false"
                               data-bind="checked: diagnosisProvisional" class="tasks-list-cb"/>
                        <span class="tasks-list-mark"></span>
                        <span class="tasks-list-desc">Final</span>
                    </label>
                </div>
            </div>

            <div>
                <input type="text" style="width: 450px" id="diagnoses" name="diagnosis" placeholder="Enter Diagnosis">

                <field>
                    <input type="hidden" id="diagnosis-set" class=""/>
                    <span id="diagnosis-lbl" class="field-error" style="display: none"></span>
                </field>

                <div class="tasks" id="task-diagnosis" style="display:none;">
                    <header class="tasks-header">
                        <span id="title-diagnosis" class="tasks-title">PATIENT'S DIAGNOSIS</span>
                        <a class="tasks-lists"></a>
                    </header>

                    <div id="diagnosis-holder"></div>
                </div>
                <select style="display: none" id="selectedDiagnosisList"></select>

                <div class="selectdiv" id="selected-diagnosis"></div>
            </div>
        </fieldset>

        <fieldset class="no-confirmation">
            <legend>Investigations</legend>

            <div>
                <label for="investigation" class="label title-label">Investigations <span class="important"></span>
                </label>
                <input type="text" style="width: 450px" id="investigation" name="investigation"
                       placeholder="Enter Investigations">

                <field>
                    <input type="hidden" id="investigations-set" class=""/>
                    <span id="investigations-lbl" class="field-error" style="display: none"></span>
                </field>

                <div class="tasks" id="task-investigations" style="display:none;">
                    <header class="tasks-header">
                        <span id="title-symptom" class="tasks-title">PATIENT'S INVESTIGATIONS</span>
                        <a class="tasks-lists"></a>
                    </header>

                    <div id="investigations-holder"></div>
                </div>

                <select style="display: none" id="selectedInvestigationList"></select>

                <div class="selectdiv" id="selected-investigations"></div>
            </div>
        </fieldset>

        <fieldset class="no-confirmation">
            <legend>Treatment</legend>
            <label class="label title-label" style="width: auto;">Treatment</label>

            <field>
                <input type="hidden" id="treatment-info-set" class=""/>
                <span id="tretament-info-lbl" class="field-error" style="display: none"></span>
            </field>

            <div class="onerow floating-controls treatment-info">
                <div class="col4" style="width: 50%; margin: 0 1% 0 0">
                    <div class="testbox">
                        <div>Received LLITN?</div>
                        <label>
                            <input type="radio" data-value="Yes"
                                   name="concept.160428AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                                   value="4536f271-5430-4345-b5f7-37ca4cfe1553">
                            Yes
                        </label><br/>

                        <label>
                            <input type="radio" data-value="No"
                                   name="concept.160428AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                                   value="606720bb-4a7a-4c4c-b3b5-9a8e910758c9">
                            No
                        </label>
                    </div>

                    <div class="testbox">
                        <div>Dewormed</div>
                        <label>
                            <input type="radio" data-value="Yes"
                                   name="concept.159922AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                                   value="4536f271-5430-4345-b5f7-37ca4cfe1553">
                            Yes
                        </label><br/>

                        <label>
                            <input type="radio" data-value="No"
                                   name="concept.159922AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                                   value="606720bb-4a7a-4c4c-b3b5-9a8e910758c9">
                            No
                        </label>
                    </div>
                </div>

                <div class="col4 last" style="width: 49%;">
                    <div class="testbox">
                        <div>Vitamin A Supplementation (6-59 months)</div>
                        <label>
                            <input type="radio" data-value="Yes"
                                   name="concept.c1346a48-9777-428f-a908-e8bff24e4e37"
                                   value="4536f271-5430-4345-b5f7-37ca4cfe1553">
                            Yes
                        </label><br/>

                        <label>
                            <input type="radio" data-value="No"
                                   name="concept.c1346a48-9777-428f-a908-e8bff24e4e37"
                                   value="606720bb-4a7a-4c4c-b3b5-9a8e910758c9">
                            No
                        </label>
                    </div>

                    <div class="testbox">
                        <div>Supplemented with MNP (6-23 months)</div>
                        <label>
                            <input type="radio" data-value="Yes"
                                   name="concept.534705aa-8857-4e70-9b08-b363fb3ce677"
                                   value="4536f271-5430-4345-b5f7-37ca4cfe1553">
                            Yes
                        </label><br/>

                        <label>
                            <input type="radio" data-value="No"
                                   name="concept.534705aa-8857-4e70-9b08-b363fb3ce677"
                                   value="606720bb-4a7a-4c4c-b3b5-9a8e910758c9">
                            No
                        </label>
                    </div>
                </div>
            </div>
        </fieldset>

        <fieldset>
            <legend>Infant Feeeding</legend>
            <label class="label title-label" style="width: auto;">Infant Feeding</label>

            <field>
                <input type="hidden" id="feeding-info-set" class=""/>
                <span id="feeding-info-lbl" class="field-error" style="display: none"></span>
            </field>

            <div class="onerow floating-controls feeding-info">
                <div class="col4" style="width: 50%; margin: 0 1% 0 0">
                    <div class="testbox">
                        <div>Exclusive Breastfeeding(0-6 mnths)</div>
                        <label>
                            <input id="exclusive-breast-feeding" type="radio" data-value="Yes"
                                   name="concept.a082375c-bfe4-4395-9ed5-d58e9ab0edd3"
                                   value="4536f271-5430-4345-b5f7-37ca4cfe1553">
                            Yes
                        </label><br/>

                        <label>
                            <input id="exclusive-breast-feeding" type="radio" data-value="No"
                                   name="concept.a082375c-bfe4-4395-9ed5-d58e9ab0edd3"
                                   value="606720bb-4a7a-4c4c-b3b5-9a8e910758c9">
                            No
                        </label>
                    </div>

                    <div class="testbox">
                        <div>Counseled on HIV?</div>
                        <label>
                            <input id="hiv-counseled" type="radio" data-value="Yes"
                                   name="concept.8a3c420e-b4ff-4710-81fd-90c7bfa6de72"
                                   value="4536f271-5430-4345-b5f7-37ca4cfe1553">
                            Yes
                        </label><br/>

                        <label>
                            <input id="hiv-counseled" type="radio" data-value="No"
                                   name="concept.8a3c420e-b4ff-4710-81fd-90c7bfa6de72"
                                   value="606720bb-4a7a-4c4c-b3b5-9a8e910758c9">
                            No
                        </label>
                    </div>
                </div>

                <div class="col4 last" style="width: 49%;">
                    <div class="testbox">
                        <div>Counseled on Nutrition?</div>
                        <label>
                            <input id="counseled-nutrition" type="radio" data-value="Yes"
                                   name="concept.42197783-8b24-49b0-b290-cbb368fa0113"
                                   value="4536f271-5430-4345-b5f7-37ca4cfe1553">
                            Yes
                        </label><br/>

                        <label>
                            <input id="counseled-nutrition" type="radio" data-value="No"
                                   name="concept.42197783-8b24-49b0-b290-cbb368fa0113"
                                   value="606720bb-4a7a-4c4c-b3b5-9a8e910758c9">
                            No
                        </label>
                    </div>

                    <div class="testbox">
                        <div>Any Disability?</div>
                        <label style="width: 70px">
                            <input type="radio" name="concept.d311a2d5-8af3-4161-9df4-35f26b04dded"
                                   value="4536f271-5430-4345-b5f7-37ca4cfe1553">
                            Yes
                        </label>

                        <input id="specific-disability" type="text" placeholder="Specify Disability"
                               style="width: 70% ! important; display: none; float: right ! important; margin-right: 3px;"
                               name="concept.bfa43093-bc99-4273-8c3f-5232f631f6aa">
                        <br/>

                        <label>
                            <input type="radio" name="concept.d311a2d5-8af3-4161-9df4-35f26b04dded"
                                   value="606720bb-4a7a-4c4c-b3b5-9a8e910758c9">
                            No
                        </label>
                    </div>
                </div>
            </div>
        </fieldset>

        <fieldset class="no-confirmation">
            <legend>Prescription</legend>
            <label class="label title-label">Prescription <span class="important"></span></label>

            <table class="drug-table">
                <thead>
                <tr>
                    <th>Drug Name</th>
                    <th>Dosage</th>
                    <th>Formulation</th>
                    <th>Frequency</th>
                    <th>Days</th>
                    <th>Comments</th>
                    <th></th>
                </tr>
                </thead>

                <tbody data-bind="foreach: display_drug_orders">
                <tr>
                    <td data-bind="text: drug_name"></td>
                    <td data-bind="text: (dosage + ' ' + dosage_unit_label)"></td>
                    <td data-bind="text: formulation_label"></td>
                    <td data-bind="text: frequency_label"></td>
                    <td data-bind="text: number_of_days"></td>
                    <td data-bind="text: comment"></td>
                    <td data-bind="click: \$parent.remove">
                        <i class="icon-remove small" style="cursor: pointer; color: #f00;"></i>
                    </td>
                </tr>
                </tbody>

                <tbody data-bind="visible: display_drug_orders().length==0">
                <tr>
                    <td colspan="8">
                        <div style="padding: 6px 10px; border-top: 1px solid #ddd; border-bottom: 3px solid #ddd; margin: -5px -10px;">No Drugs Added Yet</div>
                    </td>
                </tr>
                </tbody>
            </table>

            <field>
                <input type="hidden" id="prescriptions-set" class=""/>
                <span id="prescriptions-lbl" class="field-error" style="display: none"></span>
            </field>

            <div style="margin-top:5px">
                <span class="button confirm" id="addDrugsButton" style="float: right; margin-right: 0px;">
                    <i class="icon-plus-sign"></i>
                    Add Drugs
                </span>
            </div>
        </fieldset>

        <fieldset>
            <legend>Referral/Follow Up</legend>

            <field>
                <input type="hidden" id="referral-set" class=""/>
                <span id="referral-lbl" class="field-error" style="display: none"></span>
            </field>

            <div class="label title-label"
                 style="width: auto; border-bottom: 1px solid rgb(221, 221, 221); padding: 10px 0px 2px 10px;">Follow Up & Next Visit</div>

            <div class="onerow floating-controls conditions-info">
                <div class="col4" style="width: 50%; margin: 0 1% 0 0">
                    <div id="cwcFollowUp" class="testbox" style="height: 170px">
                        <div>Follow Up</div>

                        <% if (cwcFollowUpList != null || cwcFollowUpList != "") { %>
                        <% cwcFollowUpList.each { followUp -> %>
                        <label style="width: 100%!important;">
                            <input type="checkbox" name="concept.6f7b4285-a04b-4f8b-be85-81c325289539"
                                   value="${followUp.answerConcept.uuid}" id="${followUp.answerConcept.uuid}">
                            ${followUp.answerConcept.name}
                        </label>
                        <% } %>
                        <% } %><br/>
                        <label style="width: 100%!important;">
                            <input id="specifyOther" type="text" name="concept.7cdc2d69-31b9-4592-9a3f-4bc167d5780b"
                                   placeholder="Please Specify"
                                   style="display: none; width: 70% ! important; float: right ! important; margin: -27px 5px 5px;">
                        </label>
                        <span class="clear"></span>
                    </div>
                </div>

                <div class="col4 last" style="width: 49%;">
                    <div class="testbox" style="height: 170px">
                        <div style="margin-bottom: 5px;">Next Visit</div>
                        ${
                                ui.includeFragment("uicommons", "field/datetimepicker", [formFieldName: 'concept.ac5c88af-3104-4ca2-b1f7-2073b1364065', id: 'next-visit-date', label: 'Next Visit Date', useTime: false, defaultToday: true, startToday: true, class: ['searchFieldChange', 'date-pick', 'searchFieldBlur']])}
                    </div>
                </div>
            </div>

            <div class="clear"></div>

            <div class="label title-label"
                 style="width: auto; border-bottom: 1px solid rgb(221, 221, 221); padding: 20px 0px 2px 10px;">Referral Options</span></div>

            <div class="onerow">
                <div class="col4">
                    <label for="availableReferral">Referral Available</label>
                    <select id="availableReferral" name="availableReferral">
                        <option value="0">Select Option</option>
                        <option value="1">Internal Referral</option>
                        <option value="2">External Referral</option>
                    </select>
                </div>

                <div class="col4">
                    <div id="internalRefferalDiv" style="display: none">
                        <label for="internalRefferal">Internal Referral</label>
                        <select id="internalRefferal" name="internalRefferal">
                            <option value="0">Select Option</option>
                            <% if (internalReferrals != null || internalReferrals != "") { %>
                            <% internalReferrals.each { internalReferral -> %>
                            <option value="${internalReferral.uuid}">${internalReferral.label}</option>
                            <% } %>
                            <% } %>
                        </select>
                    </div>

                    <div id="externalRefferalDiv" style="display: none">
                        <label>External Referral</label>
                        <select id="externalRefferal" name="concept.18b2b617-1631-457f-a36b-e593d948707f">
                            <option value="0">Select Option</option>
                            <% if (externalReferrals != null || externalReferrals != "") { %>
                            <% externalReferrals.each { externalReferral -> %>
                            <option value="${externalReferral.uuid}">${externalReferral.label}</option>
                            <% } %>
                            <% } %>
                        </select>
                    </div>
                </div>

                <div class="col4 last">
                    <div id="externalRefferalFac" style="display: none">
                        <label>Facility</label>
                        <input type="text" id="referralFacility" name="concept.161562AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA">
                    </div>
                </div>
            </div>

            <div class="onerow">
                <div class="col4">
                    <div id="externalRefferalRsn" style="display: none">
                        <label for="referralReason">Referral Reason</label>
                        <select id="referralReason" name="concept.cb2890d4-e3de-449a-9d34-c9f59e87945a">
                            <option value="0">Select Option</option>
                            <% if (referralReasons != null || referralReasons != "") { %>
                            <% referralReasons.each { referralReason -> %>
                            <option value="${referralReason.uuid}">${referralReason.label}</option>
                            <% } %>
                            <% } %>
                        </select>
                    </div>
                </div>

                <div class="col4 last" style="width: 65%;">
                    <div id="externalRefferalSpc" style="display: none">
                        <label for="specify" style="width: 200px">If Other, Please Specify</label>
                        <input id="specify" type="text" name="" placeholder="Please Specify" style="display: inline;">
                    </div>
                </div>
            </div>

            <div class="onerow">
                <div id="externalRefferalCom" style="display: none">
                    <label for="comments">Comment</label>
                    <textarea id="comments" name="comment.18b2b617-1631-457f-a36b-e593d948707f"
                              style="width: 95.7%; resize: none;"></textarea>
                </div>

            </div>
        </fieldset>
    </section>

    <div id="confirmation" style="width:74.6%; min-height: 400px;">
        <span id="confirmation_label" class="title">Confirmation</span>

        <div class="dashboard">
            <div class="info-section">
                <div class="info-header">
                    <i class="icon-list-ul"></i>

                    <h3>CWC SUMMARY &amp; CONFIRMATION</h3>
                </div>

                <div class="info-body">
                    <% if (opdConcept.equalsIgnoreCase("MCH CLINIC")) { %>
                    <table id="summaryTable">
                        <tbody>
                        <tr>
                            <td><span class="status active"></span>Symptoms</td>
                            <td>N/A</td>
                        </tr>

                        <tr>
                            <td><span class="status active"></span>Examinations</td>
                            <td>N/A</td>
                        </tr>

                        <tr>
                            <td><span class="status active"></span>Prescriptions</td>
                            <td>N/A</td>
                        </tr>

                        <tr>
                            <td><span class="status active"></span>Diagnosis</td>
                            <td>N/A</td>
                        </tr>

                        <tr>
                            <td><span class="status active"></span>Investigations</td>
                            <td>N/A</td>
                        </tr>

                        <tr>
                            <td><span class="status active"></span>Infant Feeding</td>
                            <td>N/A</td>
                        </tr>

                        <tr>
                            <td><span class="status active"></span>Treatment</td>
                            <td>N/A</td>
                        </tr>

                        <tr>
                            <td><span class="status active"></span>Follow Up</td>
                            <td>N/A</td>
                        </tr>

                        <tr>
                            <td><span class="status active"></span>Outcome</td>
                            <td>N/A</td>
                        </tr>
                        </tbody>
                    </table>
                    <% } %>

                    <div>
                        <label style="padding: 3px 10px; border: 1px solid rgb(255, 247, 153); background: rgb(255, 247, 153) none repeat scroll 0px 0px; cursor: pointer; font-weight: normal; margin-top: 12px; width: 96.5%; margin-bottom: 0px;">
                            <input type="checkbox" name="send_for_examination"
                                   value="4e87c99b-8451-4789-91d8-2aa33fe1e5f6"/>
                            Send to Immunization Room
                        </label>

                        <label style="padding: 3px 10px; border: 1px solid rgb(255, 247, 153); background: rgb(255, 247, 153) none repeat scroll 0px 0px; cursor: pointer; font-weight: normal; width: 96.5%; margin-top: -3px;">
                            <input id="exitPatientFromProgramme" type="checkbox" name="exitPatientFromProgramme">
                            Exit Patient from Program
                        </label>
                    </div>
                </div>
            </div>
        </div>

        <div id="confirmationQuestion" class="focused" style="margin-top:20px">
            <field style="display: inline">
                <button class="button submit confirm" style="display: none;"></button>
            </field>

            <span value="Submit" class="button submit confirm" id="antenatalExaminationSubmitButton">
                <i class="icon-save small"></i>
                Save
            </span>

            <span id="cancelButton" class="button cancel">
                <i class="icon-remove small"></i>
                Cancel
            </span>
        </div>
    </div>
</form>

<% } else { %>

<style>
	#formBreadcrumb {
		display: none;
	}
</style>

<form method="post" id="cwcExaminationsForm">
    <input type="hidden" name="patientId" value="${patient?.patientId}">
    <input type="hidden" name="queueId" value="${queueId}">

    <div style="padding: 0 4px">
        <field>
            <input type="hidden" id="immunizations-set" class=""/>
            <span id="immunizations-lbl" class="field-error" style="display: none"></span>
        </field>

        <div style="width: 100%;" class="col16 dashboard">
            <% patientProgram.program.workflows.each { workflow -> %>
            <% def stateId; def stateStart; def stateName; %>
            <div class="info-section">
                <% patientProgram.states.each { state -> %>
                <% if (!state.voided && state.state.programWorkflow.programWorkflowId == workflow.programWorkflowId && state.active) {
                    stateId = state.state.concept.conceptId;
                    stateName = state.state.concept.name;
                    stateStart = state.startDate;
                } %>
                <% } %>

                <div class="info-header">
                    <i class="icon-medicine"></i>

                    <h3>${workflow.concept.name}</h3>
                    <a><i class="icon-chevron-right small right chevron"
                          data-idnt="${workflow.programWorkflowId}" data-name="${workflow.concept.name}"
                          data-prog="${patientProgram.patientProgramId}"></i></a>
                </div>

                <div class="info-body">
                    <div id="currentStateVaccine_${workflow.programWorkflowId}" style="display: none;">
                        <table id="workflowTable_${workflow.programWorkflowId}">
                            <thead>
                            <tr>
                            <thead>
                            <th>#</th>
                            <th>VACCINE</th>
                            <th>GIVEN ON</th>
                            <th>AT AGE</th>
                            <th>RECORDED</th>
                            <th>PROVIDER</th>
                            </thead>
                        </tr>
                        </thead>

                            <tbody>

                            </tbody>
                        </table>

                        <div class="update-vaccine">
                            <a data-idnt="${workflow.programWorkflowId}" data-name="${workflow.concept.name}"
                               data-prog="${patientProgram.patientProgramId}">
                                <i class="icon-pencil small"></i>
                                Update Vaccine
                            </a>
                        </div>

                        <div class="">&nbsp;</div>

                        <div style="display: none">
                            <select name="changeToState_${workflow.programWorkflowId}"
                                    id="changeToState_${workflow.programWorkflowId}">
                                <option value="0">Select a State</option>
                                <% if (workflow.states != null || workflow.states != "") { %>
                                <% workflow.states.each { state -> %>
                                <option id="${state.id}"
                                        value="${state.id}">${state.concept.name}</option>
                                <% } %>
                                <% } %>
                            </select>
                        </div>
                    </div>

                    <div id="currentStateDetails_${workflow.programWorkflowId}">
                        <% if (stateId != null) { %>
                        <div id='main-show-${workflow.programWorkflowId}'>
                            <span class="status active"></span>
                            <span id="state_name_${workflow.programWorkflowId}">${stateName}</span>

                            <small style="font-size: 77%; margin-left: 10px;">
                                ( <span class="icon-time"></span>
                                Date: <span id="state_date_${workflow.programWorkflowId}">${
                                    ui.formatDatePretty(stateStart)}</span> )
                            </small>
                        </div>
                        <% } else { %>
                        <div id="no-show-${workflow.programWorkflowId}"
                             style="margin-left: 20px; color: rgb(153, 153, 153);">
                            <em>(No Previous Vaccinations Found)</em>
                        </div>

                        <div id='main-show-${workflow.programWorkflowId}' style="display: none;">
                            <span class="status active"></span>
                            <span id="state_name_${workflow.programWorkflowId}"></span>

                            <small style="font-size: 77%; margin-left: 10px;">
                                ( <span class="icon-time"></span>
                                Date: <span id="state_date_${workflow.programWorkflowId}"></span> )
                            </small>
                        </div>
                        <% } %>

                    </div>
                </div>
            </div>
            <% } %>
			
			<div class="info-section">
				 <div class="info-header">
                    <i class="icon-medicine"></i>
                    <h3>IMMUNIZATION STATUS</h3>
                </div>
				
				<div class="info-body">
					<div>
						<div style="margin-left: 20px;">
							<label style="cursor: pointer; font-weight: normal; width: 90%; padding: 0px; margin: 0px 0px 5px;">
								<input name="child_fully_immunized" value="true" type="checkbox" ${immunizationStatus=='true'?'checked':''}>
								Child is fully immunized
							</label>
						</div>
					</div>
				</div>
            </div>

        </div>
    </div>

    <div class="clear"></div>

    <div style="margin: -15px 9px 0px;">
        <label style="padding: 3px 10px; border: 1px solid rgb(255, 247, 153); background: rgb(255, 247, 153) none repeat scroll 0px 0px; cursor: pointer; font-weight: normal; margin-top: 12px; width: 96.7%; margin-bottom: 0px;">
            <input type="checkbox" name="send_for_examination" value="11303942-75cd-442a-aead-ae1d2ea9b3eb"/>
            Send to Examination Room
        </label>

        <label style="padding: 7px 10px 3px; border: 1px solid #fff799; background: rgb(255, 247, 153) none repeat scroll 0px 0px; cursor: pointer; font-weight: normal; margin-top: -10px; width: 96.7%; display: block;">
            <input id="exitPatientFromProgramme" type="checkbox" name="exitPatientFromProgramme">
            Exit Patient from Program
        </label>
    </div>

    <div id="confirmationQuestion" class="focused" style="margin:5px 10px 20px 4px">
        <span value="Submit" class="button submit confirm" id="antenatalExaminationSubmitButton" style="float: right;">
            <i class="icon-save small"></i>
            Save
        </span>

        <span id="cancelButton" class="button cancel">
            <i class="icon-remove small"></i>
            Cancel
        </span>
    </div>
</form>
<% } %>

<div id="prescription-dialog" class="dialog" style="display:none;">
    <div class="dialog-header">
        <i class="icon-folder-open"></i>

        <h3>Prescription</h3>
    </div>

    <div class="dialog-content">
        <form id="drugForm">
            <ul>
                <li>
                    <label>Drug</label>
                    <input class="drug-name" id="drugName" type="text">
                </li>
                <li>
                    <label>Dosage<span class="important">*<span></label>
                    <input type="text" id="drugDosage" style="width: 60px !important;">
                    <select id="drugUnitsSelect" style="width: 174px !important;">
                        <option value="0">Select Unit</option>
                    </select>
                </li>

                <li>
                    <label>Formulation</label>
                    <select id="formulationsSelect">
                        <option value="0">Select Formulation</option>
                    </select>
                </li>
                <li>
                    <label>Frequency</label>
                    <select id="frequencysSelect">
                        <option value="0">Select Frequency</option>
                    </select>
                </li>

                <li>
                    <label>Number of Days<span class="important">*<span></label>
                    <input id="numberOfDays" type="text">
                </li>
                <li>
                    <label>Comment</label>
                    <textarea id="comment"></textarea>
                </li>
            </ul>
            <label class="button confirm" style="float: right; width: auto!important;">Confirm</label>
            <label class="button cancel" style="width: auto!important;">Cancel</label>
        </form>
    </div>
</div>

<div id="exitCwcDialog" class="dialog" style="display: none;">
    <div class="dialog-header">
        <i class="icon-folder-open"></i>
        <h3>Exit From Program</h3>
    </div>

    <div class="dialog-content">
        <ul>
            <li>
                <label>Program</label>
                <input type="text" readonly="" value="CHILD WELFARE CLINIC">
            </li>

            <li>
                ${ui.includeFragment("uicommons", "field/datetimepicker", [id: 'complete-date', label: 'Completion Date', formFieldName: 'referredDate', useTime: false, defaultToday: true, endDate: new Date(), startDate: patientProgram.dateEnrolled])}
            </li>

            <li>
                <label for="programOutcome">Outcome</label>
                <select name="programOutcome" id="programOutcome">
                    <option value="0">Choose Outcome</option>
                    <% if (possibleProgramOutcomes != null || possibleProgramOutcomes != "") { %>
                    <% possibleProgramOutcomes.each { outcome -> %>
                    <option id="${outcome.id}" value="${outcome.id}">${outcome.name}</option>
                    <% } %>
                    <% } %>
                </select>
            </li>

            <button class="button confirm" id="processProgramExit" style="float: right; margin-right: 18px;">
                <i class="icon-save small"></i>
                Save
            </button>
            <span class="button cancel">Cancel</span>
        </ul>
    </div>
</div>

<div id="vaccinations-dialog" class="dialog" style="display: none;">
    <div class="dialog-header">
        <i class="icon-folder-open"></i>
        <h3>UPDATE VACCINE</h3>
    </div>

    <div class="dialog-content">
        <ul>
            <li>
                <label for="vaccine-name">Vaccine Name:</label>
                <input type="text" id="vaccine-name" readonly="">
                <input type="hidden" id="vaccine-idnt" readonly="">
                <input type="hidden" id="vaccine-prog" readonly="">
            </li>

            <li>
                <label for="vaccine-state">Change State:</label>
                <select id="vaccine-state">
                    <option value="0">Select a State</option>
                </select>
            </li>
            <li>
                <label for="vaccine-batch">Batch:</label>
                <select id="vaccine-batch">
                    <option value="0">Select a Batch</option>
                </select>
            </li>
			
			<li>
                <label for="vaccine-stage">VVM Stage:</label>
                <select id="vaccine-stage">
                    <option value="0">Select Stage</option>
                    <option value="1">Stage 01</option>
                    <option value="2">Stage 02</option>
                    <option value="3">Stage 03</option>
                    <option value="4">Stage 04</option>
                </select>
            </li>
			
            <li>
                <label for="vaccine-quantity">Quantity:</label>
                <input type="text" id="vaccine-quantity" name="vaccine-quantity" value="1"/>
            </li>


            <li>
                ${ui.includeFragment("uicommons", "field/datetimepicker", [formFieldName: 'vaccine-date', id: 'vaccine-date', label: 'Change Date', useTime: false, defaultToday: true, startDate: patient?.birthdate, endDate: new Date()])}
            </li>

            <span class="button confirm" style="float: right; margin-right: 17px;">
                <i class="icon-save small"></i>
                Save
            </span>

            <span class="button cancel">Cancel</span>
        </ul>
    </div>
</div>
