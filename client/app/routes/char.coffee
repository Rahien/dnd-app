`import Ember from 'ember'`
`import Char from '../models/character'`
`import AuthRoute from '../utils/auth-route'`
`import SendMessage from '../mixins/send-message'`

CharRoute = AuthRoute.extend SendMessage,
  activate: ->
    # Hack: need to take this way out... security restriction on fake click of input
    # click has to be sent from within event handling context (o-m-g)
    # don't have didInsertElement... :(
    Ember.run.later ( ->
      Ember.$(".button.upload").click ->
         Ember.$(".uploadInput").click();
    ), 500
  model: (params) ->
    @store.findRecord 'character', params.id

`export default CharRoute`
