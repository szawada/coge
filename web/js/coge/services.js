/* 
 * CoGe Web Services API
 */

var coge = window.coge = (function(namespace) {
	// Local constants
	var BASE_URL = "api/v1/";
	
	// Methods
	namespace.services = {
		init: function(opts) {
			if (opts.baseUrl)
				this.BASE_URL = opts.baseUrl;
			if (opts.userName)
				this.userName = opts.userName;
			this.debug = 1;
		},
		
		search_organisms: function(search_term) {
			// TODO add param validation
			return this._ajax("GET", BASE_URL + "organisms/search/" + search_term + "/");
		},

		add_organism: function(request) {
			return this._ajax("PUT", BASE_URL + "organisms/", JSON.stringify(request));
		},
		
		search_genomes: function(search_term, opts) {
			// TODO add param validation
			return this._ajax("GET", BASE_URL + "genomes/search/" + search_term + "/", null, opts);
		},
			
		search_notebooks: function(search_term) {
			// TODO add param validation
			return this._ajax("GET", BASE_URL + "notebooks/search/" + search_term + "/");
		},
		
		search_users: function(search_term) {
			// TODO add param validation
			return this._ajax("GET", BASE_URL + "users/search/" + search_term + "/");
		},
		
		submit_job: function(request) {
			return this._ajax("PUT", BASE_URL + "jobs/", JSON.stringify(request));
		},
		
		fetch_job: function(id) {
			this._debug('fetch_job');
			if (!id) {
				this._error('fetch_job: missing id value');
				return;
			}
			return this._ajax("GET", BASE_URL + "jobs/" + id);
		},
		
		fetch_logs: function(id, type) {
			this._debug('fetch_logs');
			if (!id || !type) {
				this._error('fetch_job: missing id/type value');
				return;
			}
			return this._ajax("GET", BASE_URL + "logs/" + type + '/' + id);
		},
		
		irods_list: function(path) {
			return this._ajax("GET", BASE_URL + "irods/list/" + path);
		},
		
		_ajax: function(type, url, data, opts) { //, success, error) {
			var self = this;
			
			// Build param list
			var opts_str = '';
			if (this.userName)
				opts_str += "username=" + this.userName;
			for (key in opts) {
				if (opts_str)
					opts_str += "&";
				opts_str += key + "=" + opts[key];
			}
			
			// Return deferred
		    return $.ajax({
				    	type: type,
				    	url: url + (opts_str ? "?" + opts_str : ''),
				    	dataType: "json",
				        contentType: "application/json",
				        xhrFields: {
			                withCredentials: true
			            },
				        data: data,
				    })
				    .fail(function(jqXHR, textStatus, errorThrown) { 
				    	self._error('ajax:error: ' + jqXHR.status + ' ' + jqXHR.statusText); 
				    });		
		},
		
		_error: function(string) {
			console.error('services: ' + string);
		},
		
		_debug: function(string) {
			if (this.debug)
				console.log('services: ' + string);
		}
	
    };

	// TODO add auth code
	
    return namespace;
})(coge || {});