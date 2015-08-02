`import Ember from 'ember'`

LoginRoute = Ember.Route.extend
  onActivate: Ember.on 'activate', ->
    @set 'user.username', null
    @set 'user.password', null
  renderTemplate: ->
    @_super arguments...
    # yuk. I should make this a component I guess, so I have didInsertElement
    Ember.run.later this, ( ->
      Ember.$('.login .user input')[0].focus()
    ), 500

`export default LoginRoute`
