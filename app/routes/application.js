import Ember from 'ember';

var Route = Ember.Route.extend({
	intl: Ember.inject.service(),
  session: Ember.inject.service('session'),
  observeSessionData: Ember.observer('session.data.authenticated.access_token', function(){
			this.get('session.data.authenticated.access_token');
			this.get('session').authorize('authorizer:oauth2', function(headerName, headerValue){
					var headers = {};
					headers[headerName] = headerValue;
					Ember.$.ajaxSetup({headers: headers});
			});
	}.on('init')),
  beforeModel: function () {
    this.get('intl').setLocale('en-us');
	},
  actions: {
    showMessage: function (message) {
      var messages = this.get('controller.messages');
      messages.addObject(message);
		  var remover = function() {
			  this.removeMessage(message);
			};
      if(message.autoClose !== false && (message.type !== "error" || message.autoClose)){
        Ember.run.later(this.get('controller'), remover, (message.autoClose || 5000));
			}
      return false;
		}
	}
});

export default Route;
