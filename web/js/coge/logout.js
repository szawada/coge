var coge = window.coge = (function (namespace) {
	var DEFAULT_INTERVAL = 2*1000; // ms
	
    namespace.logout = {

        init: function(params) {
        	if (!$.cookie) {
        		console.error('logout.init: jQuery cookie plugin is not loaded!');
        		return;
        	}
        	
        	if (!params) {
        		console.error('logout.init: Missing required parameter object');
        		return;
        	}
        	
        	if (params.loginCookieName) {
        		this.loginCookieName = params.loginCookieName;
        		console.log("logout.init: loginCookieName='" + this.loginCookieName + "'");
        	}
        	else {
        		console.warn('logout.init: Disabling logout detection due to missing parameter loginCookieName (this is not necessarily an error)');
        		return;
        	}
        	
        	if (params.loginCallback) {
        		this.loginCallback = params.loginCallback;
        	}
        	else {
        		console.error('logout.init: Missing required parameter: loginCallback');
        		return;
        	}
        	
        	this.interval = DEFAULT_INTERVAL;
        	if (params.interval)
        		this.interal = params.interval;
        	
        	// Start logout check timer
        	if (this.isLoggedIn()) {
        		this.initLoggedIn = true;
        		this.start();
        	}
        	else {
        		console.log('logout.init: Not logged in currently')
        	}
        },
        
        start: function() {
        	this.timer = setInterval(this.checkLogin.bind(this), this.interval);
        },
        
        stop: function() {
        	clearInterval(this.timer);
        },
        
        isLoggedIn: function() {
        	var cookie = $.cookie(this.loginCookieName);
    		if (!cookie)
    			return 0;
    		return 1;
        },
        
        checkLogin: function() {
        	var self = this;
        	console.log('logout.checkLogin');
        	
        	if (this.isLoggedIn())
        		return;
        	
    		console.log("logout.checkLogin: Session cookie doesn't exist");
    		this.stop();
    		
    		var dialog = $("<div />") // TODO move rendering into separate function
    			.html("Your login session has expired. Please login or continue as a public user.")
    			.dialog({
    				title: "Your session has expired ...",
	    			dialogClass: "no-close",
	    			closeOnEscape: false,
	    			height: 'auto',
	    			modal: true,
	    	        resizable: false,
	    			buttons: [
		    			{
			    			text: "Login",
			    			click: function() {
			    				self.loginCallback();
			    			}
		    			},
		    			{
			    			text: "Cancel",
			    			click: function() {
			    				window.location.reload(false);
			    			}
		    			}
	    			],
	    			open: function(event, ui) { // hide close 'X' button
	    		        $(".ui-dialog-titlebar-close", ui.dialog | ui).hide();
	    		    }
        		});
        }

    };
    
    return namespace;
})(coge || {});
