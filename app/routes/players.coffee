`import Ember from 'ember'`
`import AuthRoute from '../utils/auth-route'`
`import SendMessage from '../mixins/send-message'`

PlayersRoute = AuthRoute.extend SendMessage,
  # map of open players, cannot keep it in the model because of reloads
  openMap: {}
  model: ->
    new Ember.RSVP.Promise (resolve, reject) =>
      Ember.$.ajax "/dnd/api/players",
        type: "GET"
        dataType: "json"
        success: (response) =>
          (response or []).map (player) =>
            Ember.set player, "open", @get("openMap.#{player._id}")
          resolve(response)
        error: (error) =>
          reject error
  actions:
    openCharacter: (char) ->
      @transitionTo 'char', char._id
    togglePlayer: (player) ->
      open = not Ember.get(player,'open')
      Ember.set player, 'open', open
      @set "openMap.#{player._id}", open
    linkCharacter: (player, char) ->
      characters = [char._id]
      player.chars.map (item) ->
        if item._id != char._id
          characters.push item._id

      Ember.$.ajax "/dnd/api/player/#{player._id}/chars",
        type: "PUT"
        contentType: "application/json; charset=utf-8"
        data: JSON.stringify(characters)
        success: =>
          @refresh()
        error: (error) =>
          @sendMessage 'error', "Could not add character to  #{player.username}. #{error.responseText}"
    unlinkChar: (player, char) ->
      characters = []
      player.chars.map (item) ->
        if item._id != char._id
          characters.push item._id

      Ember.$.ajax "/dnd/api/player/#{player._id}/chars",
        type: "PUT"
        contentType: "application/json; charset=utf-8"
        data: JSON.stringify(characters)
        success: =>
          @refresh()
        error: (error) =>
          @sendMessage 'error', "Could not unlink #{player.username}. #{error.responseText}"
    removeChar: (char) ->
      Ember.$.ajax "/dnd/api/char/#{char._id}",
        method: "DELETE"
        success: =>
          @refresh()
        error: =>
          @sendMessage 'error', "Could not remove character!"
    removePlayer: (player) ->
      Ember.$.ajax "/dnd/api/player/#{player._id}",
        type: "DELETE"
        success: =>
          @refresh()
        error: (error) =>
          @sendMessage 'error', "Could not remove #{player.username}. #{error.responseText}"
    toggleAdmin: (player) ->
      Ember.$.ajax "/dnd/api/setAdmin",
        type: "POST"
        contentType: "application/json; charset=utf-8"
        data: JSON.stringify
          user: player._id
          admin: not player.isAdmin
        success: =>
          @refresh()
        error: (error) =>
          @sendMessage 'error', "Could not change admin status of #{player.username}. #{error.responseText}"

`export default PlayersRoute`
