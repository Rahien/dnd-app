`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`
`import SaveLoad from '../mixins/save-load-model'`
`import Char from '../models/char'`
`import Adventure from '../models/adventure'`

AdventureController = Ember.Controller.extend SendMessage, SaveLoad,
  hasPlayers: Ember.computed.notEmpty "model.chars"
  filename: Ember.computed "model.name", ->
    name = @get 'model.name'
    name.replace(/[^a-z0-9]/gi, '_').toLowerCase();
  deduplicatePlayers: (players) ->
    result = {}
    players.map (player) ->
      result[player._id] = player
    Object.keys(result).map (id) ->
      result[id]
  updatePlayers: (newPlayers) ->
    newPlayers = @deduplicatePlayers newPlayers
    @set('model.chars', newPlayers)
    Ember.$.ajax "/dnd/api/adventure/#{@get('model._id')}",
      type: "PUT"
      contentType: "application/json; charset=utf-8"
      data: JSON.stringify({ chars: newPlayers })
      success: =>
        @sendMessage 'goodstuff', "Players updated"
      error: (error) =>
        @sendMessage 'error', "Could not update players: #{error.responseText}"
  fetchCharacter: (id) -> new Ember.RSVP.Promise (resolve, reject) =>
    Ember.$.ajax "/dnd/api/char/#{id}",
      type: "GET"
      contentType: "application/json; charset=utf-8"
      success: (result) =>
        resolve(result)
      error: (error) =>
        reject(error)
  doSave: ->
    serialized = @get('model').serialize()
    delete serialized._id
    Ember.$.ajax "/dnd/api/adventure/#{@get('model._id')}",
      type: "PUT"
      contentType: "application/json; charset=utf-8"
      data: JSON.stringify(serialized)
      success: =>
        @sendMessage 'goodstuff', "Adventure saved"
      error: (error) =>
        @sendMessage 'error', "Could not save adventure: #{error.responseText}"
  modelFromObject: (object) ->
    Adventure.create object
  actions:
    addPlayer: ->
      @set 'showModal', true
    closeDialog: ->
      @set 'showModal', false
    delete: ->
      Ember.$.ajax "/dnd/api/adventure/#{@get('model._id')}",
        type: "DELETE"
        contentType: "application/json; charset=utf-8"
        success: =>
          @sendMessage 'goodstuff', "Adventure removed"
          @transitionToRoute 'adventures'
        error: (error) =>
          @sendMessage 'error', "Could not remove adventure: #{error.responseText}"
    save: ->
      @doSave()
    linkCharacter: (target, character) ->
      @fetchCharacter(character._id).then( (result) =>
        players = @get('model.chars').concat([])
        # do not store all this here, it is just a mirror of the char
        result.spellGroups = {}
        result.gear = []
        result = Char.create result
        players.push(result)
        @updatePlayers(players)
        @set 'showModal', false
      ).catch (error) =>
        @sendMessage 'error', "Could not update players: #{error.responseText}"
    unlinkCharacter: (character) ->
      players = @get('model.chars').concat([])
      index = -1
      
      players.map (player, i) ->
        if player._id == character._id
          index= i

      if index > -1
        players.splice(index,1)
        @updatePlayers(players)

`export default AdventureController`