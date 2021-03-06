//Global Variables
var user_is_admin = false;

$(function () {
	// Initialize CoGe web services
    coge.services.init({
    	baseUrl: API_BASE_URL,
    	userName: USER_NAME
    });
    
    // See if the current user is an admin
    $.ajax({
		data: {
			fname: 'user_is_admin',
		},
		success: function(data) {
			user_is_admin = data == 1;
		}
	}).done(function() {
		search_stuff(SEARCH_TERM);
	});
});

function search_stuff(search_term) {
	if (!search_term || search_term.length <= 2) {
		$("#noresult").html('Please specify a search term longer than 2 characters').show();
		$("#loading").hide();
		return;
	}
	
	$("#noresult").hide();
	$('masterTable').css('display', 'none');
	$("#loading").show();
	
	coge.services.search_global(search_term)
		.done(function(response) {
			//console.log(response);
			var obj = response;
			
			if (!obj || !obj.results)
				return;

			function add_item(html, url, obj) {
				html += '<tr><td>';
				if (url) {
					html += '<a target="_blank" href="';
					html += url;
					html += obj.id;
					html += '"';
				} 
				else
					html += '<span';
				if (obj.description) {
					html += ' title=';
					html += JSON.stringify(obj.description);
				}
				if (obj.deleted == 1)
					html += ' style="color:red;"';
				html += '>';
				if (obj.favorite)
					html += '&#11088;&nbsp;&nbsp;';
				if (obj.certified)
					html += '&#x2705;&nbsp;&nbsp;';
				if (obj.restricted)
					html += '&#x1f512;&nbsp;&nbsp;';
				html += obj.name;
				html += url ? '</a>' : '</span>';
				html += '</td><td>';
				html += obj.id;
				html += '</td></tr>';
				return html;
			}
			
			var userCounter = 0, orgCounter = 0, genCounter = 0, expCounter = 0, noteCounter = 0, usrgroupCounter = 0;
			var userList = "", orgList = "", genList = "", expList = "", noteList = "", usrgroupList = "";

			for (var i = 0; i < obj.results.length; i++) {
				var o = obj.results[i];
				// if (o.type == "user") {
				// 	userList += "<tr><td>";
				// 	userList += o.first + " " + o.last;
				// 	if (user_is_admin)
				// 		userList += ", " + o.email;
				// 	userList += " (" + o.username + ", id" + o.id + ") ";
				// 	userList += "<button onclick=\"search_user(" + o.id + ",'user')\">Show Data</button>";
				// 	userList += "</td></tr>";
				// 	userCounter++;
				// }

				if (o.type == "organism") {
					orgList = add_item(orgList, 'OrganismView.pl?oid=', o);
					orgCounter++;
				}

				if (o.type == "genome") {
					if (o.deleted != 1 || user_is_admin) {
						genList = add_item(genList, 'GenomeInfo.pl?gid=', o);
						genCounter++;
					}
				}

				if (o.type == "experiment") {
					if (o.deleted != 1 || user_is_admin) {
						expList = add_item(expList, 'ExperimentView.pl?eid=', o);
						expCounter++;
					}
				}

				if (o.type == "notebook") {
					if (o.deleted != 1 || user_is_admin) {
						noteList = add_item(noteList, 'NotebookView.pl?lid=', o);
						noteCounter++;
					}
				}
						
				if (o.type == "user_group") {
					if (o.deleted != 1 || user_is_admin) {
						usrgroupList = add_item(usrgroupList, null, o);
						usrgroupCounter++;
					}
				}
			}
			

			//Populate the html with the results
			$("#loading").show();
			$('masterTable').css('display', 'block');
			$(".result").fadeIn( 'fast');
			
			if (userCounter + orgCounter + genCounter + expCounter + noteCounter + usrgroupCounter == 0)
				$('#noresult').html('No matching results found').show();
			
			//user
			if(userCounter > 0) {
				$('#user').show();
				$('#userCount').html("Users: " + userCounter);
				$('#userList').html('<tr><th>name</th><th style="width:100px;">id</th></tr>' + userList);
//				if(userCounter <= 10) {
//					$( "#userList" ).show();
//					//$( "#userArrow" ).find('img').toggle();
//					$("#userArrow").find('img').attr("src", "picts/arrow-down-icon.png");
//				} 
//				else {
					$( "#userList" ).hide();
					$("#userArrow").find('img').attr("src", "picts/arrow-right-icon.png");
//				}
			} else {
				$('#user').hide();
			}
			
			//organism
			if(orgCounter > 0) {
				$('#organism').show();
				$('#orgCount').html("Organisms: " + orgCounter);
				$('#orgList').html('<tr><th>name</th><th style="width:100px;">id</th></tr>' + orgList);
//				if(orgCounter <= 10) {
//					$( "#orgList" ).show();
//					//$( "#orgArrow" ).find('img').toggle();
//					$( "#orgArrow" ).find('img').attr("src", "picts/arrow-down-icon.png");
//				} 
//				else {
					$( "#orgList" ).hide();
					$("#orgArrow").find('img').attr("src", "picts/arrow-right-icon.png");
//				}
			} else {
				$('#organism').hide();
			}
			
			//genome
			if(genCounter > 0) {
				$('#genome').show();
				$('#genCount').html("Genomes: " + genCounter);
				$('#genList').html('<tr><th>name</th><th style="width:100px;">id</th></tr>' + genList);
//				if(genCounter <= 10) {
//					$( "#genList" ).show();
//					//$( "#genArrow" ).find('img').toggle();
//					$( "#genArrow" ).find('img').attr("src", "picts/arrow-down-icon.png");
//				} 
//				else {
					$( "#genList" ).hide();
					$("#genArrow").find('img').attr("src", "picts/arrow-right-icon.png");
//				}
			} else {
				$('#genome').hide();
			}
			
			//experiment
			if(expCounter > 0) {
				$('#experiment').show();
				$('#expCount').html("Experiments: " + expCounter);
				$('#expList').html('<tr><th>name</th><th style="width:100px;">id</th></tr>' + expList);
//				if(expCounter <= 10) {
//					$( "#expList" ).show();
//					//$( "#expArrow" ).find('img').toggle();
//					$( "#expArrow" ).find('img').attr("src", "picts/arrow-down-icon.png");
//				} 
//				else {
					$( "#expList" ).hide();
					$("#expArrow").find('img').attr("src", "picts/arrow-right-icon.png");
//				}
			} else {
				$('#experiment').hide();
			}
			
			//notebook
			if(noteCounter > 0) {
				$('#notebook').show();
				$('#noteCount').html("Notebooks: " + noteCounter);
				$('#noteList').html('<tr><th>name</th><th style="width:100px;">id</th></tr>' + noteList);
//				if(noteCounter <= 10) {
//					$( "#noteList" ).show();
//					//$( "#noteArrow" ).find('img').toggle();
//					$( "#noteArrow" ).find('img').attr("src", "picts/arrow-down-icon.png");
//				} 
//				else {
					$( "#noteList" ).hide();
					$("#noteArrow").find('img').attr("src", "picts/arrow-right-icon.png");
//				}
			} else {
				$('#notebook').hide();
			}
			
			//user group
			if(usrgroupCounter > 0) {
				$('#user_group').show();
				$('#usrgroupCount').html("User Groups: " + usrgroupCounter);
				$('#usrgroupList').html('<tr><th>name</th><th style="width:100px;">id</th></tr>' + usrgroupList);
//				if (usrgroupCounter <= 10) {
//					$( "#usrgroupList" ).show();
//					//$( "#usrGArrow" ).find('img').toggle();
//					$("#usrGArrow").find('img').attr("src", "picts/arrow-down-icon.png");
//				} 
//				else {
					$( "#usrgroupList" ).hide();
					$("#usrGArrow").find('img').attr("src", "picts/arrow-right-icon.png");
//				}
			} else {
				$('#user_group').hide();
			}
			
			$("#loading").hide();
			$("#masterTable").show();
			if (!user_is_admin)
				$(".access").hide();
			else
				$(".access").show();
		})
		.fail(function() {
			$("#loading").hide();
			$("#masterTable").html("An error occured. Please reload the page and try again.");
		});
	
	//previous_search = search_term;
}

function toggle_arrow(id) {
	if ( $(id).find('img').attr('src') == "picts/arrow-right-icon.png" ) {
        $(id).find('img').attr("src", "picts/arrow-down-icon.png");
    }
	else {
		$(id).find('img').attr("src", "picts/arrow-right-icon.png");
	}
}

function show_table(id) {
	$(id).fadeToggle('fast');	
}