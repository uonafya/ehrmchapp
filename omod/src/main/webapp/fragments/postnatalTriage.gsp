<script>
	
    jq(function(){
    	var isEdit=${isEdit};
 	       jq("#editStatus").val(isEdit?"true":"false");
        var patientProfile = JSON.parse('${patientProfile}');
        if (patientProfile.details.length > 0) {
            var patientProfileTemplate = _.template(jq("#patient-profile-template").html());
            jq(".patient-profile").append(patientProfileTemplate(patientProfile));
        } else {
            jq(".patient-profile-editor").prependTo(jq(".profile-editor"));
        }

        jq(".patient-profile").on("click", ".edit-profile", function(){
            jq(".patient-profile").empty();
            jq("<span style='margin-top: 5px; display: block;'><a href=\"#\" class=\"cancel\"><i class='icon-remove small'></i>Cancel Edit</a></span>").appendTo(jq(".patient-profile"));
			jq(".patient-profile-editor").prependTo(jq(".profile-editor"));
            for (var i = 0; i < patientProfile.details.length; i++) {
                if (isValidDate(patientProfile.details[i].value)) {
                    jq("input[name\$='"+ patientProfile.details[i].uuid +"']").val(moment(patientProfile.details[i].value, 'D MMM YYYY').format('YYYY-MM-DD'));
                    jq("#"+ patientProfile.details[i].uuid + "-display").val(moment(patientProfile.details[i].value, 'D MMM YYYY').format('DD MMM YYYY'));
                } else {
                    jq("input[name\$='"+ patientProfile.details[i].uuid +"']").val(patientProfile.details[i].value);
                }
            }
        });

        jq(".patient-profile").on("click", ".cancel", function(e){
            e.preventDefault();
            jq('.patient-profile-editor').appendTo('.template-holder');
            jq(':input','.patient-profile-editor')
				.val('')
				.removeAttr('checked')
				.removeAttr('selected');
            if (patientProfile.details.length > 0) {
                var patientProfileTemplate = _.template(jq("#patient-profile-template").html());
                jq(".patient-profile").append(patientProfileTemplate(patientProfile));
            }
			jq(this).remove();
        });
		
		jq(".submit").on("click", function(event){
			event.preventDefault();
			
			if (jq('form #deliveryMode').val() == "0"){
				jq().toastmessage('showErrorToast', 'Please select the mode of delivery.');
				return false;
			}

			var data = jq("form#pnc-triage-form").serialize();

			jq.post(
				'${ui.actionLink("mchapp", "postnatalTriage", "savePostnatalTriageInformation")}',
				data,
				function (data) {
					if (data.status === "success") {
						//show success message
						if(data.isEdit){
							window.location = "${ui.pageLink("mchapp", "main",[patientId: patientId, queueId: queueId])}";
						}else{
							window.location = "${ui.pageLink("patientqueueapp", "mchTriageQueue")}"
							 }
						} else if (data.status === "error") {
						//show error message;
						jq().toastmessage('showErrorToast', data.message);
					}
				}, 
				"json");
		});
    });
</script>

<script id="patient-profile-template" type="text/template">
    {{ _.each(details, function(detail) { }}
		<span class="menu-title">
			<i class="icon-angle-right"></i>
			<span>{{=detail.name}}:</span>{{=detail.value}}
		</span>
    {{ }); }}
	
	<span class="menu-title">
		<i class="icon-angle-right"></i>
		<span>Others:</span>None
	</span>
	
	<span style="border-top: 1px dotted rgb(136, 136, 136); display: block; margin-top: 5px; padding-top: 5px;">
		<a href="#" class="edit-profile">
			<i class="icon-pencil"></i>
			Edit Details
		</a>	
	</span>
</script>

<div>
	<div style="padding-top: 15px;" class="col15 clear">
		<ul id="left-menu" class="left-menu">
			<li class="menu-item selected" visitid="54">
				<span class="menu-date">
					<i class="icon-time"></i>
					<span id="vistdate">${patientProgram?patientProgram.dateEnrolled:"--"}"<br> &nbsp; &nbsp; (Active since 04:10 PM)</span>
				</span>
				<div class="patient-profile">
				</div>				
				
				<span class="arrow-border"></span>
				<span class="arrow"></span>
			</li>

			<li style="height: 30px;" class="menu-item" visitid="53">
			</li>
		</ul>
	</div>
	
	
	<div style="min-width: 70%" class="col16 dashboard">
		<div class="info-section">
			<form id="pnc-triage-form">
				<input type="hidden" value="" id="editStatus" name="isEdit"/>
				<input type="hidden" name="patientId" value="${patient.patientId}" >
				<input type="hidden" name="queueId" value="${queueId}" >
				<input type="hidden" name="patientEnrollmentDate" value="${patientProgram?patientProgram.dateEnrolled:"--"}">
				<div class="profile-editor"></div>
				
				<div class="info-header">
					<i class="icon-diagnosis"></i>
					<h3>TRIAGE DETAILS</h3>
				</div>
				
				<div class="info-body">						
					<input type="hidden" name="patientId" value="${patientId}" >
					<div>
						<label for="temperature">Temperature</label>
						<input type="text" name="concept.5088AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" class="number numeric-range" value="${temperature}">
						<span class="append-to-value">..&#8451;</span>
						<span id="12464" class="field-error" style="display: none"></span>
					</div>
					
					<div>
						<label for="pulse">Pulse</label>
						<input type="text" name="concept.5087AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" class="number numeric-range" value="${pulseRate}">
						<span id="12463" class="field-error" style="display: none"></span>
					</div>
					<div>
						<label for="bloodPressure">Blood Pressure</label>
						<input type="text" id="systolic" name="concept.5085AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" class="number numeric-range" value="${systolic}" />
						<span class="append-to-value">Systolic</span>
						<span id="12462" class="field-error" style="display: none"></span>
					</div>
					
					<div>
						<label for="diastolic"></label>
						<input type="text" id="diastolic" name="concept.5086AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" class="number numeric-range" value="${daistolic}" />
						<span class="append-to-value">Diastolic</span>
						<span id="12465" class="field-error" style="display: none"></span>
					</div>					
					
					<% if(!isEdit){ %>
					<div>
						<label></label>
						<label style="padding-left: 0px; width: auto; cursor: pointer;">
							<input type="checkbox" name="send_for_examination" value="1acb3707-9e03-40e3-b157-ce28451c3fd0" >
							Tick to Send to Examination Room
						</label>
					</div>
					<%	} %>
				</div>
			</form>
			
			<div>
				<span class="button submit confirm right" id="antenatalTriageFormSubmitButton" style="margin-top: 10px; margin-right: 30px;">
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

<div class="template-holder" style="display:none;">
	<div class="patient-profile-editor">
		<div class="info-header">
			<i class="icon-user-md"></i>
			<h3>POST-NATAL DETAILS</h3>
		</div>
		
		<div class="info-body" style="margin-bottom: 20px; padding-bottom: 10px;">
			<div>				
				${ui.includeFragment("uicommons", "field/datetimepicker", [formFieldName: 'concept.5599AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', id: '5599AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', label: 'Date of Delivery', useTime: false, defaultToday: false, endDate: new Date()])}
			</div>
		
			<div>
				<label for="deliveryPlace">Place of Delivery</label>
				<input type="text" name="1572AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" >
			</div>
			
			<div>
				<label for="deliveryMode">Mode of Delivery</label>
				<select id="deliveryMode" name="concept.5630AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA">
					<option value="0">Select Option</option>					
					<% deliveryMode.each { modes -> %>
 						<option value="${modes.uuid}">${modes.label}</option>
 					<% } %>
				</select>
			</div>
			<div>
				<label for="babyState">State of Baby</label>
				<input type="text" name="concept.8f3ed313-e2ea-48df-b211-69bb3f232b20" >
			</div>
		</div>	  
	</div>
</div>
