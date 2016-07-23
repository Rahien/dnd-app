`import Ember from 'ember'`

PlayersController = Ember.Controller.extend
  init: ->
    @_super(arguments...)
    @set 'showModal', false
  
  actions:
    linkCharacter: ->
      @set 'showModal', false
      true
    requestLink: (player) ->
      @set 'linkingPlayer', player
      @set 'showModal', true
    closeDialog: ->
      @set 'showModal', false

`export default PlayersController`
