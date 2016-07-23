import Ember from 'ember';
import ApplicationRouteMixin from 'ember-simple-auth/mixins/application-route-mixin';

var Route = Ember.Route.extend(ApplicationRouteMixin, {
	intl: Ember.inject.service(),
  session: Ember.inject.service('session'),
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
