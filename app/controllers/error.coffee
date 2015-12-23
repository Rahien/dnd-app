`import Ember from 'ember'`

ErrorController = Ember.Controller.extend
  session: Ember.inject.service('session')
  errorMessage: Ember.computed 'model', ->
    model = @get 'model'
    model.responseJSON.error_description or model.responseJSON.error or JSON.stringify(model)
    # don't want to create an actual route for this, but it should be in the route...
    if model.responseJSON.error == "invalid_grant"
      @get('session').invalidate()
      @transitionToRoute 'login'

`export default ErrorController`
