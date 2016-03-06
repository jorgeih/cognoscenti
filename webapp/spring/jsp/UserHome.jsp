<%@page errorPage="/spring/jsp/error.jsp"
%><%@ include file="/spring/jsp/include.jsp"
%><%
/*
Required parameters:

    1. pageId : This is the id of a Workspace and here it is used to retrieve NGPage.

*/

    ar.assertLoggedIn("Must be logged in to see a list of meetings");


    UserProfile loggedUser = ar.getUserProfile();
    NGPageIndex.clearLocksHeldByThisThread();
    UserCache userCache = ar.getCogInstance().getUserCacheMgr().getCache(loggedUser.getKey());

    JSONArray actionItems = userCache.getActionItems();
    JSONArray openActionItems = new JSONArray();
    for (int i=0; i<actionItems.length(); i++) {
        JSONObject oneItem = actionItems.getJSONObject(i);
        int state =  oneItem.getInt("state");
        if (state==3 || state==2) {
            openActionItems.put(oneItem);
        }
    }
    JSONArray proposals = userCache.getProposals();
    JSONArray openRounds = userCache.getOpenRounds();

    List<WatchRecord> watchList = loggedUser.getWatchList();
    JSONArray wList = new JSONArray();
    for (WatchRecord wr : watchList) {
        String pageKey = wr.getPageKey();
        NGPageIndex ngpi = ar.getCogInstance().getContainerIndexByKey(pageKey);
        if (ngpi==null) {
            continue;
        }
        JSONObject wObj = ngpi.getJSON4List();
        wObj.put("visited", wr.getLastSeen());
        wList.put(wObj);
    }
    JSONArray siteList = new JSONArray();
    for (NGBook site : loggedUser.findAllMemberSites()) {
        JSONObject jObj = site.getConfigJSON();
        WorkspaceStats stats = site.getRecentStats(ar.getCogInstance());
        jObj.put("numWorkspaces", stats.numWorkspaces);
        jObj.put("numTopics", stats.numTopics);
        siteList.put(jObj);
    }


%>

<script type="text/javascript">

var app = angular.module('myApp', ['ui.bootstrap']);
app.controller('myCtrl', function($scope, $http) {
    $scope.openActionItems = <%openActionItems.write(out,2,4);%>;
    $scope.proposals   = <%proposals.write(out,2,4);%>;
    $scope.openRounds  = <%openRounds.write(out,2,4);%>;
    $scope.wList       = <%wList.write(out,2,4);%>;
    $scope.siteList    = <%siteList.write(out,2,4);%>;
    $scope.loggedUser  = <% loggedUser.getJSON().write(out,2,4);%>;
    
    $scope.wList.sort( function(a,b) {
        return a.changed-b.changed;
    });
    $scope.openActionItems.sort( function(a,b) {
        return a.duedate-b.duedate;
    });
});
</script>

<!-- MAIN CONTENT SECTION START -->
<div ng-app="myApp" ng-controller="myCtrl">

<%@include file="ErrorPanel.jsp"%>

    <div class="generalHeading" style="height:40px">
        <div  style="float:left;margin-top:8px;">
            Home for {{loggedUser.name}}
        </div>
        <div class="rightDivContent" style="margin-right:100px;">
          <span class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
            Options: <span class="caret"></span></button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
              <li role="presentation"><a role="menuitem"
                  href="">Do Nothing</a></li>
              <li role="presentation"><a role="menuitem" href="">
			      Do Nothing </a>
              </li>
            </ul>
          </span>

        </div>
    </div>

    <style>
      .tripleColumn {
          border: 1px solid white;
          border-radius:5px;
          padding:5px;
          background-color:#FFFFFF;
          margin:6px
      }
    </style>

    <table><tr style="vertical-align:top;">
    <td style="width:350px;vertial-align:top;">
       <div class="tripleColumn leafContent">
          <h1>Top Action Items</h1>
          <div>
             <ul>
               <li  ng-repeat="item in openActionItems | limitTo: 10">
                 <img src="<%=ar.retPath%>/assets/goalstate/small{{item.state}}.gif">
                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.projectKey}}/task{{item.id}}.htm">
                 {{item.synopsis|limitTo:28}}</a>
               </li>
               <li>
                 <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userActiveTasks.htm">See all action items...</a>
               </li>
             </ul>
          </div>
          <h1>Need to Respond</h1>
          <div>
             <ul>
               <li ng-repeat="item in proposals | limitTo: 10">
                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.workspaceKey}}/{{item.address}}">{{item.content|limitTo:28}}</a>
               </li>
               <li>
                 <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userMissingResponses.htm">See all ...</a>
               </li>
             </ul>
          </div>
          <h1>Need to Complete</h1>
          <div>
             <ul>
               <li ng-repeat="item in openRounds | limitTo: 10">
                 <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.workspaceKey}}/{{item.address}}">{{item.content|limitTo:28}}</a>
               </li>
               <li>
                 <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userOpenRounds.htm">See all...</a>
               </li>
             </ul>
          </div>
       </div>
    </td>
    <td style="width:350px;vertial-align:top;">
       <div class="tripleColumn leafContent">
           Some sort of cool graphic here.
       </div>
    </td>
    <td style="width:350px;vertial-align:top;">
       <div class="tripleColumn leafContent">
           <div style="margin:5px;">
               <h1>Workspaces you Watch</h1>
               <ul>
               <li ng-repeat="item in wList | limitTo: 10">
                   <a href="<%=ar.retPath%>t/{{item.siteKey}}/{{item.pageKey}}/frontPage.htm">
                   {{item.name}}
                   </a>
               </li>
               <li>
                 <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/watchedProjects.htm">See all...</a>
               </li>
               </ul>
           </div>
           <div style="margin:5px;">
               <h1>Sites you Manage</h1>
               <ul>
               <li ng-repeat="item in siteList | limitTo: 10">
                   <a href="<%=ar.retPath%>t/{{item.key}}/$/accountListProjects.htm">
                   {{item.names[0]}}
                   </a>
               </li>
               <li>
                 <a href="<%=ar.retPath%>v/<%=loggedUser.getKey()%>/userAccounts.htm">See all...</a>
               </li>
               </ul>
           </div>
       </div>
    </td>
    </tr></table>


</div>
