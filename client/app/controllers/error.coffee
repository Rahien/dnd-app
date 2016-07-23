`import Ember from 'ember'`

ErrorController = Ember.Controller.extend
  session: Ember.inject.service('session')
  errorMessage: Ember.computed 'model', ->
    model = @get 'model'
    result = ""
    (result = "#{model.status}: ") if model.status
    result += model.responseJSON?.error_description or model.responseJSON?.error or JSON.stringify(model)

`export default ErrorController`
