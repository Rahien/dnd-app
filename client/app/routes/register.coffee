`import Ember from 'ember'`

RegisterRoute = Ember.Route.extend
  afterModel: ->
    controller = @get 'controller'
    if controller and not controller.get 'destroyed'
      @set 'controller.username', null
      @set 'controller.password', null
      @set 'controller.passwordAgain', null


`export default RegisterRoute`
