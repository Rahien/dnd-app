import Ember from 'ember';

var LoginRoute = Ember.Route.extend({
  actions: {
    showMessage: function (message) {
      var messages = this.get('controller.messages');
      messages.addObject(message);
		  var remover = function() {
			  this.removeMessage(message);
			};
      if(message.type !== "error" || message.autoClose){
        Ember.run.later(this.get('controller'), remover, (message.autoClose || 5000));
			}
      return false;
		}
	}
});

export default LoginRoute;
