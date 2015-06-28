`import Ember from 'ember'`
`import Char from '../models/char'`
`import SendMessage from '../mixins/send-message'`

CharsController = Ember.Controller.extend SendMessage,
  characters: Ember.computed 'model', ->
    chars = @get('model').concat([])
    chars.sort (one,two) ->
      if one.name < two.name then -1 else 1        
  actions:
    openCharacter: (character) ->
      @transitionToRoute 'char', character._id
    newCharacter: ->
      def = Char.getDefault()
      Ember.$.ajax "/dnd/api/chars",
        type: "POST"
        username: @get 'user.username'
        password: @get 'user.password'
        contentType: "application/json; charset=utf-8"
        data: JSON.stringify(def)
        success: (result) =>
          @transitionToRoute 'char', result
        error: (error) =>
          if error.status == 401
            @transitionToRoute 'login'
          else if typeof error == "string"
            @sendMessage 'error', "Sorry, could not fetch your characters from the server, contact your administrator"

`export default CharsController`
