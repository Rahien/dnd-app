`import Ember from 'ember'`
`import Char from '../models/char'`

CharsController = Ember.Controller.extend
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
          if typeof result == "string"
            alert result
          else
            alert JSON.stringify(result)

`export default CharsController`
