`import Ember from 'ember'`

ErrorController = Ember.Controller.extend
  errorMessage: Ember.computed 'model', ->
    model = @get 'model'
    model.responseJSON.error_description or model.responseJSON.error or JSON.stringify(model)

`export default ErrorController`
