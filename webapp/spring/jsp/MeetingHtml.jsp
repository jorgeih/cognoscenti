<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%@page import="org.socialbiz.cog.MeetingRecord"
%><%@page import="org.socialbiz.cog.LicenseForUser"
%><%@page import="org.socialbiz.cog.AccessControl"
%><%@page import="org.socialbiz.cog.MicroProfileMgr"
%><%

    String pageId      = ar.reqParam("pageId");
    NGWorkspace ngw = ar.getCogInstance().getWorkspaceByKeyOrFail(pageId);
    ar.setPageAccessLevels(ngw);
    String meetId          = ar.reqParam("id");
    MeetingRecord mRec     = ngw.findMeeting(meetId);

    //comment or uncomment depending on whether you are in development testing mode
    String templateCacheDefeater = "";
    //String templateCacheDefeater = "?t="+System.currentTimeMillis();


    if (!AccessControl.canAccessMeeting(ar, ngw, mRec)) {
        throw new Exception("Please log in to see this meeting.");
    }

    if (ar.ngp==null) {
        throw new Exception("NGP should not be null!!!!!!");
    }
    
    NGBook ngb = ngw.getSite();
    UserProfile uProf = ar.getUserProfile();
    boolean isLoggedIn = (uProf!=null);
    String currentUser = "";
    String currentUserName = "Unknown";
    String currentUserKey = "";
    if (isLoggedIn) {
        currentUser = uProf.getUniversalId();
        currentUserName = uProf.getName();
        currentUserKey = uProf.getKey();
    }

    String targetRole = mRec.getTargetRole();
    if (targetRole==null || targetRole.length()==0) {
        mRec.setTargetRole(ngw.getPrimaryRole().getName());
    }
    JSONObject meetingInfo = mRec.getFullJSON(ar, ngw);
    
    JSONObject previousMeeting = new JSONObject();
    if (meetingInfo.has("previousMeeting")) {
        String previousId = meetingInfo.getString("previousMeeting");
        if (previousId.length()>0) {
            MeetingRecord previous = ngw.findMeetingOrNull(previousId);
            if (previous!=null) {
                previousMeeting = new JSONObject();
                JSONObject temp = previous.getFullJSON(ar, ngw);
                previousMeeting.put("startTime", temp.getLong("startTime"));
                previousMeeting.put("id", temp.getString("id"));
                previousMeeting.put("minutesId", temp.getString("minutesId"));
                if (temp.has("minutesLocalId")) {
                    previousMeeting.put("minutesLocalId", temp.getString("minutesLocalId"));
                }
            }
        }
    }
    
    JSONArray attachmentList = new JSONArray();
    for (AttachmentRecord doc : ngw.getAllAttachments()) {
        if (doc.isDeleted()) {
            continue;
        }
        attachmentList.put(doc.getJSON4Doc(ar, ngw));
    }

    JSONArray allGoals     = ngw.getJSONGoals();

    JSONArray allRoles = new JSONArray();
    for (NGRole aRole : ngw.getAllRoles()) {
        allRoles.put(aRole.getName());
    }

    JSONArray allTopics = new JSONArray();
    for (TopicRecord aNote : ngw.getAllNotes()) {
        allTopics.put(aNote.getJSON(ngw));
    }

    JSONArray allLabels = ngw.getJSONLabels();

    String docSpaceURL = "";

    if (uProf!=null) {
        LicenseForUser lfu = new LicenseForUser(ar.getUserProfile());
        docSpaceURL = ar.baseURL +  "api/" + ngb.getKey() + "/" + ngw.getKey()
                    + "/summary.json?lic="+lfu.getId();
    }

    MeetingRecord backlog = ngw.getAgendaItemBacklog();




%>

<style>
.meeting-icon {
   cursor:pointer;
   color:LightSteelBlue;
}

.comment-outer {
    border: 1px solid lightgrey;
    border-radius:8px;
    padding:5px;
    margin-top:15px;
    background-color:#EEE;
    cursor: pointer;
}
.comment-inner {
    border: 1px solid lightgrey;
    border-radius:6px;
    padding:5px;
    background-color:white;
}
.comment-state-draft {
    background-color:yellow;
}
.comment-state-active {
    background-color:#DEF;
}
.comment-state-complete {
    background-color:#EEE;
}
.comment-phase-change {
    border: 1px solid #DFD;
    background-color:#EFE;
}
</style>

<script>
var embeddedData = {};
embeddedData.pageId    = "<%ar.writeJS(pageId);%>";
embeddedData.meetId    = "<%ar.writeJS(meetId);%>";
embeddedData.meeting   = <%meetingInfo.write(out,2,2);%>;
embeddedData.previousMeeting = <%previousMeeting.write(out,2,2);%>;
embeddedData.allGoals  = <%allGoals.write(out,2,2);%>;
embeddedData.allRoles  = <%allRoles.write(out,2,2);%>;
embeddedData.allLabels = <%allLabels.write(out,2,2);%>;
embeddedData.backlogId = "<%=backlog.getId()%>";
embeddedData.retPath   = "<%=ar.retPath%>";
embeddedData.docSpaceURL = "<%ar.writeJS(docSpaceURL);%>"
</script>
<script src="../../../spring/jsp/MeetingFull.js"></script>

<script src="../../../jscript/AllPeople.js"></script>

<style>
[ng\:cloak], [ng-cloak], [data-ng-cloak], [x-ng-cloak], .ng-cloak, .x-ng-cloak {
  display: none !important;
}

.blankTitle {
    font-size: 130%;
    font-weight: bold;
}
.agendaTitle {
    font-size: 130%;
    font-weight: bold;
    border-style:dotted;
    border-color:white;
}
.spaceyTable tr td {
    padding:5px;
}

</style>

<div ng-app="myApp" ng-controller="myCtrl" ng-cloak>

<%@include file="ErrorPanel.jsp"%>


<%if (isLoggedIn) { %>
    <div class="upRightOptions rightDivContent">
      <span class="dropdown" title="Control the way people see this meeting.">
          <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown" style="{{meetingStateStyle(meeting.state)}}">
          State: {{stateName()}} <span class="caret"></span></button>
          <ul class="dropdown-menu" role="menu" aria-labelledby="menu1" style="cursor:pointer">
            <li role="presentation"><a role="menuitem" 
                title="Use DRAFT to set the meeting without any notifications going out"
                ng-click="changeMeetingState(0)">Draft Meeting</a></li>
            <li role="presentation"><a role="menuitem"
                title="Use PLAN to allow everyone to get prepared for the meeting"
                ng-click="changeMeetingState(1)">Plan Meeting</a></li>
            <li role="presentation"><a role="menuitem"
                title="Use RUN while the meeting is actually in session"
                ng-click="changeMeetingState(2)">Run Meeting</a></li>
            <li role="presentation"><a role="menuitem"
                title="Use COMPLETE after the meeting is over and to generate minutes"
                ng-click="changeMeetingState(3)">Complete Meeting</a></li>
          </ul>
      </span>
      <span class="dropdown">
        <button class="btn btn-default btn-raised dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
        Options: <span class="caret"></span></button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Opens or closes all of the agenda items for the meeting"
              href="#" ng-click="showAll()" >Show All Items</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Show who has responded about whether they will attend or not"
              href="#" ng-click="toggleRollCall()" >Show Roll Call</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Create a new agenda item at the bottom of the meeting"
              href="#" ng-click="createAgendaItem()" >Create Agenda Item</a></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="A special view mode to sort and arrange the agenda items more easily"
              href="meeting.htm?id={{meeting.id}}" >Arrange Agenda</a></li>
          <li role="presentation"><a role="menuitem"
              title="Compose an email messsage about this meeting and send it"
              href="sendNote.htm?meet={{meeting.id}}">Send Email about Meeting</a></li>
          <li role="presentation"><a role="menuitem"
              title="Display the meeting as a HTML page that can be copied into an editor"
              href="meetingFull.htm?id={{meeting.id}}">Show Full Display</a></li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem"
              title="Generate the meeting minutes from the agenda items and put in a discussion topic"
              ng-click="createMinutes()">Generate Minutes</a></li>
          <li role="presentation" ng-show="meeting.minutesId"><a role="menuitem"
              title="Navigate to the discussion topic that holds the minutes for this meeting"
              href="noteZoom{{meeting.minutesLocalId}}.htm">View Minutes</a></li>
          <li role="presentation" class="divider"></li>
          <li role="presentation"><a role="menuitem" tabindex="-1"
              title="Make a copy of this meeting for a new timeslot"
              href="cloneMeeting.htm?id={{meeting.id}}">Clone Meeting</a></li>
          <li role="presentation"><a role="menuitem"
              title="Return back to the list of all meetings in the workspace"
              href="meetingList.htm">List All Meetings</a></li>
        </ul>
      </span>

    </div>
<% } %>

    <div style="width:100%">
      <div class="leafContent">
        <span style="font-size:150%;font-weight: bold;">
            <i class="fa fa-gavel" style="font-size:130%"></i>
            {{meeting.name}}
        </span>
      </div>
      <br/>
      <div>
        <table class="table">
          <col width="130px">
          <col width="*">
          <col width="20px">
          <tr>
            <td>Scheduled Time:</td>
            <td>
              {{meeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}
              &nbsp &nbsp
              <a href="meetingTime{{meeting.id}}.ics" title="Make a calendar entry for this meeting">
                  <i class="fa fa-calendar"></i></a>
            </td>
            <td>
              <i class="fa fa-edit" ng-click="editMeetingInfo=true"></i>
            </td>
          </tr>
          <tr>
            <td>Called By:</td>
            <td>
              {{meeting.owner}}
            </td>
            <td></td>
          </tr>
          <tr>
            <td>Target Role:</td>
            <td>
              <a href="roleManagement.htm">{{meeting.targetRole}}</a>
            </td>
            <td>
              <i class="fa fa-edit" ng-click="editMeetingInfo=true"></i>
            </td>
          </tr>
          <tr>
            <td>Description:</td>
            <td>
              <div ng-bind-html="meeting.meetingInfo"></div>
            </td>
            <td>
              <i class="fa fa-edit" ng-click="editMeetingDesc=true"></i>
            </td>
          </tr>
          <tr ng-show="isCompleted()">
            <td>Minutes:</td>
            <td>
                <div ng-show="minutesDraft && meeting.minutesId">
                   Draft:
                   <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;background-color:yellow;"
                         title="Navigate to the discussion topic with the minutes for this meeting"
                         ng-click="navigateToTopic(meeting.minutesLocalId)">
                         View Minutes
                   </span>
                   <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                         title="if you are happy with the draft minutes as they are, use this to publish them to everyone"
                         ng-click="postMinutes(meeting.minutesLocalId)">
                         Post Minutes as they are
                   </span>
                </div>
                <div ng-show="!minutesDraft && meeting.minutesId">
                   Posted:
                   <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                         ng-click="navigateToTopic(meeting.minutesLocalId)">
                         View Minutes
                   </span>
                </div>
            </td>
            <td></td>
          </tr>
          <tr ng-show="previousMeeting.id">
            <td>Previous Meeting:</td>
            <td>
              <a href="meetingFull.htm?id={{previousMeeting.id}}">
                {{previousMeeting.startTime|date: "dd-MMM-yyyy   '&nbsp; at &nbsp;'  HH:mm  '&nbsp;  GMT'Z"}}</a>
            </td>
            <td></td>
          </tr>
          <tr ng-show="previousMeeting.minutesId">
            <td>Previous Minutes:</td>
            <td>
                <span class="btn btn-sm btn-default btn-raised"  style="margin:4px;"
                     ng-click="navigateToTopic(previousMeeting.minutesLocalId)"
                     title="Navigate to the discussion topic that holds the minutes for the previous meeting">
                     Previous Minutes
                </span>
            </td>
            <td></td>
          </tr>
          <tr>
            <td>Attendence Planning:</td>
            <td>
                <span ng-repeat="pers in peopleStatus">
                  <span>
                    <a href="">{{pers.name}}</a>
                    (
                    <span ng-show="pers.attend=='Yes'">Will attend</span>
                    <span ng-show="pers.attend=='No'">Will not attend</span>
                    <span ng-show="pers.attend=='Maybe'">Might attend</span>
                    <span ng-show="pers.attend!='Maybe' && pers.attend!='Yes' && pers.attend!='No'">Unknown</span>
                    {{pers.situation}}
                    )
                  </span>,
                </span>
            </td>
          </tr>
          <tr>
            <td>Actual Attendees:</td>
            <td>
              <span ng-repeat="person in getAttended()">
                <a href="">{{person.name}}</a>, 
              </span>
            </td>
          </tr>
          <tr><td></td><td></td><td></td>
          </tr>
        </table>
      </div>
    </div>



<style>
.agendaItemFull {
    border: 1px solid lightgrey;
    border-radius:10px;
    margin-top:20px;
}
.agendaItemBlank {
    background-color:lightgray;
    margin-top:20px;
}
</style>
<script>
</script>

<div ng-repeat="item in getAgendaItems()">
    <div class="agendaItemBlank" ng-show="item.isSpacer">
      <div style="padding:5px;">
        <div style="width:100%">
                <span class="blankTitle" ng-click="showItemMap[item.id]=!showItemMap[item.id]">
                    {{item.subject}} </span>  &nbsp;

                <span>
                    <i>({{item.duration}} minutes) {{item.schedule | date: 'HH:mm'}}
                      - {{item.scheduleEnd | date: 'HH:mm'}} </i>
                </span>
        </div>
          <div ng-show="editItemDetailsMap[item.id]" class="well" style="margin:20px">
            <div class="form-inline form-group" ng-hide="item.topicLink">
              Name: <input ng-model="item.subject"  class="form-control" style="width:200px;"
                           placeholder="Enter Agenda Item Name"/>
                    <input type="checkbox"  ng-model="item.isSpacer"
                             class="form-control" style="width:50px;"/>
                    Break Time
            </div>
            <div class="form-inline form-group">
              Duration: <input ng-model="item.duration"  class="form-control" style="width:50px;"/>
            </div>
            <div class="form-inline form-group">
              <button ng-click="savePendingEdits()" class="btn btn-primary btn-raised">Save</button>
              <button ng-click="revertAllEdits()" class="btn btn-warning btn-raised">Cancel</button>
            </div>
          </div>
      </div>
    </div>
    <div class="agendaItemFull"  ng-hide="item.isSpacer">
    <table style="width:100%">

                          <!--  AGENDA HEADER -->
      <tr>
        <td style="width:100%">
          <div style="padding:5px;">
            <div style="width:100%">
                <span class="agendaTitle">
                    {{item.number}}.
                    <i ng-show="item.topicLink" class="fa fa-lightbulb-o"></i>
                    {{item.subject}} </span>  &nbsp;

                <span style="float:right" ng-hide="item.readyToGo || isCompleted()" >
                    <img src="<%=ar.retPath%>assets/goalstate/agenda-not-ready.png"
                         title="Indicates that the agenda item does NOT have all of the documents, presentations, and is full prepared for the meeting."
                         style="width:24px;height=24px;float:right">
                </span>
                <span style="float:right" ng-show="item.readyToGo && !isCompleted()"  >
                    <img src="<%=ar.retPath%>assets/goalstate/agenda-ready-to-go.png"
                         title="Indicates that the agenda item has all of the documents, presentations, and is full prepared for the meeting."
                         style="width:24px;height=24px">
                </span>

            </div>
            <div>
                <i>
                {{item.schedule | date: 'HH:mm'}} ({{item.duration}} minutes)<span ng-repeat="pres in item.presenterList">, {{pres.name}}</span></i>
            </div>
          </div>
        </td>
      </tr>

                          <!--  AGENDA BODY -->
      <tr>
        <td style="width:100%">
          
           <div style="padding:10px">
             <div ng-bind-html="item.desc"></div>
           </div>
        </td>
      </tr>

                          <!--  AGENDA ATTACHMENTS -->
      <tr>
        <td>
           <div style="margin:10px;" ng-repeat="topic in itemTopics(item)">
              Topic: 
              <span ng-click="navigateToTopic(item.topicLink)">
                <i class="fa fa-lightbulb-o" style="font-size:130%"></i>
                <a href="">{{topic.subject}}</a>
              </span>
           </div>
        </td>
      </tr>
      <tr>
        <td>
           <div style="margin:10px;" ng-repeat="docid in item.docList">
              Attachment: 
              <span ng-click="navigateToDoc(docid)">
                <a href="">{{getFullDoc(docid).name}}</a>
              </span>
           </div>
        </td>
      </tr>
      <tr>
        <td>
           <div style="margin:10px;" ng-repeat="goal in itemGoals(item)">
              Action Item: 
              <span ng-click="navigateToDoc(docid)">
                <a href="">{{goal.synopsis}}</a>, 
                <span ng-repeat="person in goal.assignTo">{{person.name}}, </span>
                {{goal.status}}
              </span>
           </div>
        </td>
      </tr>

    </table>
    </div>



                          <!--  AGENDA comments -->
      <table ng-show="!item.isSpacer" >
      <tr ng-repeat="cmt in item.comments">

          <%@ include file="/spring/jsp/CommentView.jsp"%>

      </tr>

    </table>
    </div>

    <br/>
    <br/>
    <br/>
    <br/>
    <br/>
    
</div>

<script src="<%=ar.retPath%>templates/ModalActionItemCtrl.js"></script>
<script src="<%=ar.retPath%>templates/CommentModal.js"></script>
<script src="<%=ar.retPath%>templates/ResponseModal.js"></script>
<script src="<%=ar.retPath%>templates/OutcomeModal.js"></script>
<script src="<%=ar.retPath%>templates/DecisionModal.js"></script>
<script src="<%=ar.retPath%>templates/AttachDocumentCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachTopicCtrl.js"></script>
<script src="<%=ar.retPath%>templates/AttachActionCtrl.js"></script>
