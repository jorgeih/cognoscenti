<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.EmailRecord"
%><%@page import="org.socialbiz.cog.OptOutAddr"
%><%@page import="org.socialbiz.cog.mail.MailFile"
%><%@page import="org.socialbiz.cog.mail.MailInst"
%><%

    String msgSentDate = ar.reqParam("msg");
    long msgId = DOMFace.safeConvertLong(msgSentDate);
    String filter      = ar.defParam("f", "");
    
    String pageId = ar.reqParam("pageId");
    String siteId = ar.reqParam("siteId");
    NGWorkspace ngp = ar.getCogInstance().getWSBySiteAndKeyOrFail(siteId, pageId).getWorkspace();
    ar.setPageAccessLevels(ngp);
    ar.assertMember("Must be a member to see meetings");
    NGBook ngb = ngp.getSite();

    File folder = ngp.getFilePath().getParentFile();
    File emailFilePath = new File(folder, "mailArchive.json");

    MailFile archive = MailFile.readOrCreate(emailFilePath,3);


    MailInst emailMsg = MailFile.getMessage(ngp, msgId);
    JSONObject mailObject = new JSONObject();
    String specialBody = "";
    boolean bodyIsDeleted = false;
    if (emailMsg != null) {
        mailObject = emailMsg.getJSON();
        specialBody = emailMsg.getBodyText();
        bodyIsDeleted = specialBody.startsWith("*deleted");
    }

/* PROTOTYPE EMAIL RECORD
      {
        "from": "Keith local Test <kswenson@us.fujitsu.com>",
        "sendDate": 1431876589439,
        "status": "Sent",
        "subject": "This is a new NOTE",
        "to": ["kswenson@us.fujitsu.com"]
      },
*/


%>

<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    window.setMainPageTitle("Email Sent");
    $scope.emailMsg = <%mailObject.write(out,2,4);%>;
    $scope.filter = "<%ar.writeJS(filter);%>";
    $scope.bodyIsDeleted = <%=bodyIsDeleted%>;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.namePart = function(val) {
        var pos = val.indexOf('�');
        if (pos<0) {
            pos = val.indexOf('<');
        }
        if (pos<0) {
            return val;
        }
        return val.substring(0,pos);
    }

    $scope.bestDate = function(rec) {
        if (rec.Status == "Sent" || rec.Status == "Failed") {
            return rec.LastSentDate;
        }
        else {
            return rec.CreateDate;
        }
    }
});

</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

<div class="btn-toolbar primary-toolbar">
  <a class="btn btn-default btn-raised" href="emailSent.htm?f=<%ar.writeURLData(filter);%>">
    <i class="fa fa-list-alt material-icons"></i> Return to List</a>
</div>

<table class="table" style="max-width:800px">
  <tr>
    <td>From</td>
    <td>{{emailMsg.From}}</td>
  </tr>
  <tr>
    <td>Subject</td>
    <td>{{emailMsg.Subject}}</td>
  </tr>
  <tr>
    <td>Addressee</td>
    <td>{{emailMsg.Addressee}}</td>
  </tr>
  <tr>
    <td>Status</td>
    <td>{{emailMsg.Status}}</td>
  </tr>
  <tr ng-show="emailMsg.exception">
    <td>Error</td>
    <td><div ng-repeat="ee in emailMsg.exception.split('\n')">{{ee}}</div></td>
  </tr>
  <tr>
    <td>Created</td>
    <td>{{emailMsg.CreateDate |date:"dd-MMM-yyyy 'at' HH:mm"}}</td>
  </tr>
  <tr>
    <td>Sent</td>
    <td>{{emailMsg.LastSentDate |date:"dd-MMM-yyyy 'at' HH:mm"}}</td>
  </tr>
  <tr ng-hide="bodyIsDeleted">
    <td colspan="2"><%= specialBody %></td>
  </tr>
  <tr ng-show="bodyIsDeleted">
    <td colspan="2">
      <div style="font-family:Arial,Helvetica Neue,Helvetica,sans-serif;border: 2px solid skyblue;padding:10px;border-radius:10px;text-align:center;font-style:italic">
      <p>Email bodies are deleted 3 months after sending</p>
      <p>This email body was deleted around {{emailMsg.LastSentDate+(91*24*60*60*1000) |date:"dd-MMM-yyyy"}}</p>
      </div>   
    </td>
  </tr>
</table>

</div>


