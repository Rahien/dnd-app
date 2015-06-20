`import Ember from 'ember'`

AuthRoute = Ember.Route.extend
  beforeModel: (transition) ->
    user = @get 'user'
    if not user or not user.get('loggedIn')
      loginController = this.controllerFor 'login'
      loginController.set 'attemptedTransition', transition
    
      @transitionTo 'login'

`export default AuthRoute`
