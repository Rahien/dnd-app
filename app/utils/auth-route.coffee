`import Ember from 'ember'`
`import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';`

AuthRoute = Ember.Route.extend AuthenticatedRouteMixin,
  session: Ember.inject.service('session')
  beforeModel: (transition) ->
    if not @get('session.isAuthenticated')
      loginController = this.controllerFor 'login'
      loginController.set 'attemptedTransition', transition
    
      @transitionTo 'login'
    else
      @get('session').authorize 'authorizer:oauth2', (headerName, headerValue) => 
        headers = {}
        headers[headerName] = headerValue
        Ember.$.ajaxSetup(headers: headers)

`export default AuthRoute`
