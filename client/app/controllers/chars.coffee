`import Ember from 'ember'`
`import Char from '../models/character'`
`import SendMessage from '../mixins/send-message'`

CharsController = Ember.Controller.extend SendMessage,
  characters: Ember.computed 'model.@each.name', ->
    chars = @get('model').sortBy('name')
  hasCharacters: Ember.computed.notEmpty 'characters'
  actions:
    openCharacter: (character) ->
      @transitionToRoute 'char', character.id
    newCharacter: ->
      def = Char.getDefault(@store)
      def.save().then( (result) =>
        @transitionToRoute 'char', result.id
      ).catch (error) =>
        @sendMessage 'error', "Sorry, could not create the new character on the server, contact your administrator.\nServer reply was:\n#{error.responseText or error}"

`export default CharsController`
