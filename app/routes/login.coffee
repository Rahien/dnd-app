`import Ember from 'ember'`

LoginRoute = Ember.Route.extend
  afterModel: ->
    controller = @get 'controller'
    if controller and not controller.get 'destroyed'
      @set 'controller.username', null
      @set 'controller.password', null
  renderTemplate: ->
    @_super arguments...
    # yuk. I should make this a component I guess, so I have didInsertElement
    Ember.run.later this, ( ->
      Ember.$('.login .user input')[0]?.focus()
    ), 500

`export default LoginRoute`
