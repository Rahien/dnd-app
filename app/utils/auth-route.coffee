`import Ember from 'ember'`
`import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';`

AuthRoute = Ember.Route.extend AuthenticatedRouteMixin,
  session: Ember.inject.service('session')
  beforeModel: (transition) ->
    if not @get('session.isAuthenticated')
      loginController = this.controllerFor 'login'
      loginController.set 'attemptedTransition', transition
    
      @transitionTo 'login'

`export default AuthRoute`
