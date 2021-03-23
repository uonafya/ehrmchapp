<%
    ui.decorateWith("kenyaemr", "standardPage", [title: "MCH"])

    ui.includeJavascript("ehrcashier", "paging.js")
    ui.includeJavascript("ehrconfigs", "moment.js")
    ui.includeJavascript("ehrcashier", "common.js")
    ui.includeJavascript("ehrcashier", "jquery.PrintArea.js")
    ui.includeJavascript("ehrconfigs", "knockout-3.4.0.js")
    ui.includeJavascript("ehrconfigs", "jquery-ui-1.9.2.custom.min.js")
    ui.includeJavascript("ehrconfigs", "underscore-min.js")
    ui.includeJavascript("ehrconfigs", "emr.js")
    ui.includeJavascript("ehrconfigs", "jquery.simplemodal.1.4.4.min.js")

    ui.includeCss("ehrconfigs", "jquery-ui-1.9.2.custom.min.css")
    ui.includeCss("ehrconfigs", "referenceapplication.css")

    ui.includeJavascript("billingui", "moment.js")

    ui.includeCss("uicommons", "datatables/dataTables_jui.css")
    ui.includeJavascript("patientqueueapp", "jquery.dataTables.min.js")
%>

<script>
    jq(function () {

        console.log("${drugObject}");

    }); //end of doc ready
</script>

<div class="clear"></div>

<div>
    <div class="example">
        <ul id="breadcrumbs">
            <li>
                <a href="${ui.pageLink('referenceapplication', 'home')}">
                    <i class="icon-home small"></i></a>
            </li>

            <li>
                <i class="icon-chevron-right link"></i>
                <a href="${ui.pageLink('mchapp', 'stores')}">MCH Stores</a>
            </li>

            <li>
                <i class="icon-chevron-right link"></i>
                Receipt ID: ${title}
            </li>
        </ul>
    </div>
</div>

<div>
    ID: ${drugObject.id} <br />
    VMM Stage: ${drugObject.id} <br />
    Remark: ${drugObject.remark} <br />
    Quantity Transacted: ${drugObject.quantity} <br />
    Transaction Date: ${drugObject.createdOn} <br />
    Created By: ${drugObject.createdBy} <br />
    Transaction Drug: ${drugObject.storeDrug.inventoryDrug.name} <br />
    Drug Batch: ${drugObject.storeDrug.batchNo} <br />
    Transaction Type: ${drugObject.transactionType.transactionType} <br />
    Issued To: ${drugObject.patient == null ? "Dispensed From Stores": drugObject.patient} <br />
</div>

