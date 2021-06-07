<script>
    jq(function () {
        var isEdit = ${isEdit};
        console.log(isEdit);
        console.log("${growthStatusValue}");
        jq("#editStatus").val(isEdit ? "true" : "false");
        var wCatergoyValue = "${weightCategoryValue}";
        jq("#weightCategories").val(wCatergoyValue);
        var gStatusValue = "${growthStatusValue}";
        jq("#growthMonitor").val(gStatusValue);

        //submit data
        jq(".submit").on("click", function (event) {

            var wcat = jq("form #weightCategories").val();
            var gcat = jq("form #growthMonitor").val();
            if (wcat == "0") {
                jq().toastmessage('showErrorToast', "Select a Weight Category!");
                return false;
            }

            if (gcat == "0") {
                jq().toastmessage('showErrorToast', "Select Growth Status!");
                return false;
            }

            //validate weight, height and muac to ensure they are provided
            var wValue = jq('#weight').val();
            var hValue = jq('#height').val();
            var muacValue = jq('.muacs').val();

            if (wValue != '') {
                if (!(parseInt(wValue) > 0)) {
                    jq().toastmessage('showErrorToast', "Ensure value for Height has been properly filled!");
                    return false;
                }
            }

            if (hValue != '') {
                if (!(parseInt(hValue) > 0)) {
                    jq().toastmessage('showErrorToast', "Ensure value for Weight has been properly filled!");
                    return false;
                }
            }

            if (muacValue != '') {
                if (!(parseInt(muacValue) > 0)) {
                    jq().toastmessage('showErrorToast', "Ensure value for MUAC has been properly filled!");
                    return false;
                }
            }

            event.preventDefault();
            var data = jq("form#cwc-triage-form").serialize();

            jq.post(
                    '${ui.actionLink("mchapp", "cwcTriage", "saveCwcTriageInfo")}',
                    data,
                    function (data) {
                        if (data.status === "success") {
                            if (data.isEdit) {
                                window.location = "${ui.pageLink("mchapp", "main",[patientId: patientId, queueId: queueId])}";
                            }else {
                                window.location = "${ui.pageLink("patientqueueapp", "mchTriageQueue")}";
                            }
                        } else if (data.status === "error") {
                            //show error message;
                            jq().toastmessage('showErrorToast', data.message);
                        }
                    },
                    "json"
            );

        });
    });

</script>

<style>
	input[type="radio"] {
		-webkit-appearance: checkbox;
		-moz-appearance: checkbox;
		-ms-appearance: checkbox;
		margin: 4px 5px 0 0!important;
		cursor: pointer;
	}
</style>

<div>
    <div style="padding-top: 15px;" class="col15 clear">
        <ul id="left-menu" class="left-menu">
            <li class="menu-item selected" visitid="54">
                <span class="menu-date">
                    <i class="icon-time"></i>
                    <span id="vistdate">23 May 2016<br> &nbsp; &nbsp; (Active since 04:10 PM)</span>
                </span>

                <span class="menu-title" style="height: 25px;">
                    <i class="icon-stethoscope"></i>
                    Reviewed
                </span>

                <span class="arrow-border"></span>
                <span class="arrow"></span>
            </li>

            <li style="height: 30px;" class="menu-item" visitid="53">
            </li>
        </ul>
    </div>

    <div style="min-width: 70%" class="col16 dashboard">
        <div class="info-section">
            <form id="cwc-triage-form">
                <input type="hidden" value="" id="editStatus" name="isEdit"/>

                <div class="profile-editor"></div>

                <div class="info-header">
                    <i class="icon-user-md"></i>

                    <h3>TRIAGE DETAILS</h3>
                </div>

                <div class="info-body">
                    <input type="hidden" name="patientId" value="${patientId}">
                    <input type="hidden" name="queueId" value="${queueId}">
                    <input type="hidden" name="patientEnrollmentDate"
                           value='${patientProgram ? patientProgram.dateEnrolled : "--"}'>

                    <div>
                        <label for="weight">Weight</label>
                        <input type="text" id="weight" class="number numeric-range" value="${weight}"
                               name="concept.5089AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"/>

                        <span class="append-to-value">Kgs</span>
                        <span id="12520" class="field-error" style="display: none"></span>
                    </div>

                    <div>
                        <label for="weightCategories">Weight Categories</label>
                        <select id="weightCategories" name="concept.1854AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" class="coded">
                            <option value="0">Select Category</option>
                            <% weightCategories.each { category -> %>
                            <option value="${category.uuid}">${category.label}</option>
                            <% } %>
                        </select>
                        <span id="12519" class="field-error" style="display: none"></span>
                    </div>

                    <div>
                        <label for="height">Height</label>
                        <input type="text" id="height" class="number numeric-range" value="${height}"
                               name="concept.5090AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"/>
                        <span class="append-to-value">Cms</span>
                        <span id="12516" class="field-error" style="display: none"></span>
                    </div>

                    <div>
                        <label for="concept.1343AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA">M.U.A.C</label>
                        <input class="muacs number numeric-range focused"
                               type="text"
                               max="999" min="0" maxlength="7" value="${muac}"
                               name="concept.1343AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                               id="concept.1343AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA">
                        <span class="append-to-value">cm</span>
                        <span id="12518" class="field-error" style="display: none"></span>
                    </div>

                    <div>
                        <label for="growthMonitor">Growth Status</label>
                        <select id="growthMonitor" name="concept.fb577873-ea93-49f9-a3e7-82ae5035bbd2">
                            <option value="0">Select Category</option>
                            <% growthCategories.each { category -> %>
                            <option value="${category.uuid}">${category.label}</option>
                            <% } %>
                        </select>
                    </div>

                    <% if (!isEdit) { %>
                    <div>
                        <label></label>
                        <label style="padding-left:0px; width: auto; cursor: pointer;">
                            <input type="radio" name="send_for_examination" value="1acb3707-9e03-40e3-b157-ce28451c3fd0">
                            Send to Examination Room
                        </label><br/>
						
                        <label></label>
                        <label style="padding-left:0px; width: auto; cursor: pointer;">
                            <input type="radio" name="send_for_examination" value="f00b4314-cec5-4ce7-b0cd-c43e8deea664">
                            Send to Immunization Room
                        </label>
                    </div>
                    <% } %>
                </div>
            </form>

            <div>
                <span class="button submit confirm right" id="antenatalTriageFormSubmitButton"
                      style="margin-top: 10px; margin-right: 30px;">
                    <i class="icon-save"></i>
                    Save
                </span>
            </div>
        </div>
    </div>
</div>

<div class="container">
    <br style="clear: both">
</div>