<%@page errorPage="/spring/jsp/error.jsp"
%><%@page import="org.socialbiz.cog.ErrorLog"
%><%@page import="org.socialbiz.cog.ErrorLogDetails"
%><%@page import="java.text.ParsePosition"
%><%@ include file="/spring/jsp/include.jsp"
%><%

    SimpleDateFormat sdf = new SimpleDateFormat("MM/dd/yyyy");
    String searchDate = ar.defParam("searchDate", null);
    if (searchDate==null) {
        //put today in if no date given
        searchDate = sdf.format(new Date());
    }
    long errorDate = sdf.parse(searchDate, new ParsePosition(0)).getTime();
    long oneDay = 24L*60*60*1000;
    String errorDateStr = sdf.format(new Date(errorDate));
    String previousDate = sdf.format(new Date(errorDate-oneDay));
    String nextDate = sdf.format(new Date(errorDate+oneDay));

    Cognoscenti cog = Cognoscenti.getInstance(request);
    ErrorLog eLog = ErrorLog.getLogForDate(errorDate, cog);
    JSONArray allDetails = new JSONArray();
    for (ErrorLogDetails eld  : eLog.getAllDetails()) {
        JSONObject jo = eld.getJSON();
        allDetails.put(jo);
    }


%>
<script type="text/javascript">

var app = angular.module('myApp');
app.controller('myCtrl', function($scope, $http) {
    $scope.allDetails = <%allDetails.write(out,2,4);%>;

    $scope.logFilePath = "<% ar.writeJS(eLog.getFilePath().toString()); %>";
    $scope.newDate = "<%=searchDate%>";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.newSearch = function() {
        window.location = "errorLog.htm?searchDate="+$scope.newDate;
    }

});

</script>


<div ng-app="myApp" ng-controller="myCtrl">


    <div class="h1">Error Log for <%=searchDate%>  
    <a href="errorLog.htm?searchDate=<%=previousDate%>" title="View <%=previousDate%>">
        <i class="fa  fa-arrow-circle-left"></i></a>
    <a href="errorLog.htm?searchDate=<%=nextDate%>" title="View <%=nextDate%>">
        <i class="fa  fa-arrow-circle-right"></i></a>
    </div>
        

    Search date: <input ng-model="newDate"> <button ng-click="newSearch()">search</button>

   <table class="table">
      <tr ng-repeat="row in allDetails">
         <td><a href="errorDetails{{row.errNo}}.htm?searchByDate=<%=errorDate%>">{{row.errNo}}</a></td>
         <td>{{row.message}}</td>
         <td style="width:100px">{{row.modTime | date}}</td>
      </tr>
   </table>

</div>


