
app.controller('CommentModalCtrl', function ($scope, $modalInstance, $modal, $interval, cmt, parentScope, AllPeople, attachmentList, docSpaceURL) {

    // initial comment object
    $scope.cmt = cmt;
    $scope.flattenedCmt = JSON.stringify(cmt);
    if (!cmt.docList) {
        cmt.docList = [];
    }
	if (!cmt.notify) {
		cmt.notify = [];
	}
	cmt.suppressEmail = (cmt.suppressEmail==true);
    // parent scope with all the crud methods
    $scope.parentScope = parentScope;
    // are there unsaved changes?
	$scope.unsaved = 0;
	// controls if comment can be saved
	$scope.saveDisabled = false;
    
    $scope.docSpaceURL = docSpaceURL;
    $scope.attachmentList = attachmentList;
    $scope.showEmail = false;
    if (!$scope.cmt.responses) {
        $scope.cmt.responses = [];
    }
    $scope.responders = [];
    
    if (cmt.commentType==2 || cmt.commentType==3) {
        $scope.cmt.responses.forEach( function(item)  {
            $scope.responders.push({
                "uid": item.user,
                "name": item.userName,
                "key": item.key
            });
        });
    }
	
	// return a readable status message
	$scope.getStatusMassage = function() {
		switch ($scope.unsaved) {
            case -1:    return "Autosave completed";
            case 0:     return "No changes";
            case 1:     return "Unsaved changes";
        }
	};
	
    $scope.tinymceOptions = standardTinyMCEOptions();
    $scope.tinymceOptions.height = 300;
	$scope.tinymceOptions.init_instance_callback = function(editor) {
        $scope.initialContent = editor.getContent();
	    editor.on('Change', tinymceChangeTrigger);
        editor.on('KeyUp', tinymceChangeTrigger);
        editor.on('Paste', tinymceChangeTrigger);
        editor.on('Remove', tinymceChangeTrigger);
        editor.on('Format', tinymceChangeTrigger);

    }

    function tinymceChangeTrigger(e, editor) {
        if (tinyMCE.activeEditor.getContent() != $scope.initialContent) {
            $scope.unsaved = 1;
        }
    }

    $scope.postIt = function () {
        if ($scope.cmt.state == 11 && $scope.autosaveEnabled) {
            $scope.cmt.state = 12;
        }
        if ($scope.cmt.state==12) {
            if ($scope.cmt.commentType==1 || $scope.cmt.commentType==5) {
                $scope.cmt.state=13;
            }
        }
        $scope.saveAndClose();
   };

    $scope.save = function() {
        if ($scope.cmt.commentType==2 || $scope.cmt.commentType==3) {
            console.log("RESPONDERS: ", $scope.responders)
            $scope.responders.forEach( function(userRec) {
                assureResponderZ(userRec);
            });
            console.log("RESPONCES: ", $scope.cmt.responses);
        }
		//assure that the uid is set for raw email addresses entered
		$scope.cmt.notify.forEach( function(item) {
			if (!item.uid) {
				item.uid = item.name;
			}
		});
		console.log("SAVING COMMENT: ", $scope.cmt);
		$scope.saveDisabled = true;
		$scope.$$hashKey = 250;
        $scope.parentScope.updateComment($scope.cmt);
        $scope.unsaved = 0;
        $scope.cmt.isNew = false;
        $scope.flattenedCmt = JSON.stringify($scope.cmt);       
    }
    
    function assureResponderZ(userRec) {
        var found = false;
        $scope.cmt.responses.forEach( function(resp) {
            if (resp.user == userRec.uid) {
                found = true;
            }
        });
        if (!found) {
            $scope.cmt.responses.push({
                "choice": "None",
                "html": "",
                "user": userRec.uid
            })
            console.log("ADDING responder: "+userRec.uid, $scope.cmt);
        }
    }

    $scope.saveAndClose = function () {
		
		// warn message if there are unsaved changes
		var r = true;
		$scope.save();
		
		// stop autosave interval
        $interval.cancel($scope.promiseAutosave);
		
        $modalInstance.dismiss('cancel');
    };

    $scope.commentTypeName = function() {
        if ($scope.cmt.commentType==2) {
            return "Proposal";
        }
        if ($scope.cmt.commentType==3) {
            return "Round";
        }
        if ($scope.cmt.commentType==5) {
            return "Minutes";
        }
        return "Comment";
    }

    $scope.getVerbHeader = function() {
        if ($scope.cmt.isNew) {
            return "Create";
        }
        return "Update";
    }
	
    $scope.datePickOptions = {
        formatYear: 'yyyy',
        startingDay: 1
    };
    $scope.datePickOpen1 = false;
    $scope.openDatePicker1 = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.datePickOpen1 = true;
    };
    $scope.datePickDisable = function(date, mode) {
        return false;
    };

    /** AUTOSAVE
     * this part of the controller enables an autosave every 30 seconds
     */
    // TODO Make autosave interval configureable
    // TODO Add autosave enable/disable to configuration
	
	// check for updateComment() in parent scope to disable autosave
	$scope.autosaveEnabled = true;
	if ($scope.parentScope.updateComment == undefined) {
		$scope.autosaveEnabled = false;
    }
	
    $scope.autosave = function() {
        var newFlat = JSON.stringify($scope.cmt);
        if (newFlat != $scope.flattenedCmt ) {
            $scope.save();
            $scope.unsaved = -1;
        }
    }
	if ($scope.autosaveEnabled) {
		$scope.promiseAutosave = $interval($scope.autosave, 15000);
    }
    
    $scope.loadPersonList = function(query) {
        return AllPeople.findMatchingPeople(query);
    }
    $scope.itemHasDoc = function(doc) {
        var res = false;
        var found = $scope.cmt.docList.forEach( function(docid) {
            if (docid == doc.universalid) {
                res = true;
            }
        });
        return res;
    }
    $scope.getDocs = function() {
        return $scope.attachmentList.filter( function(oneDoc) {
            return $scope.itemHasDoc(oneDoc);
        });
    }
    $scope.getFullDoc = function(docId) {
        var doc = {};
        $scope.attachmentList.filter( function(item) {
            if (item.universalid == docId) {
                doc = item;
            }
        });
        return doc;
    }
    $scope.navigateToDoc = function(docId) {
        var doc = $scope.getFullDoc(docId);
        window.location="docinfo"+doc.id+".htm";
    }
    $scope.openAttachDocument = function () {

        var attachModalInstance = $modal.open({
            animation: true,
            templateUrl: '../../../templates/AttachDocument.html?s=a',
            controller: 'AttachDocumentCtrl',
            size: 'lg',
            resolve: {
                docList: function () {
                    return JSON.parse(JSON.stringify($scope.cmt.docList));
                },
                attachmentList: function() {
                    return $scope.attachmentList;
                },
                docSpaceURL: function() {
                    return $scope.docSpaceURL;
                }
            }
        });

        attachModalInstance.result
        .then(function (docList) {
            $scope.cmt.docList = docList;
        }, function () {
            //cancel action - nothing really to do
        });
    };
    $scope.selectedTab = "Update";

});