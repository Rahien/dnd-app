`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`

LinkCharacterComponent = Ember.Component.extend SendMessage,
  classNames: ["link-character"]
  init: ->
    @_super(arguments...)
    @set 'characters', null
    @fetchCharacters()
  fetchCharacters: ->
    Ember.$.ajax "/dnd/api/allchars",
      type: "GET"
      dataType: 'json'
      success: (response) =>
        @set 'characters', response 
      error: =>
        @sendMessage 'error', "Could not fetch the list of all characters"
  hasCharacters: Ember.computed.bool 'characters'
  actions:
    closeDialog: ->
      @sendAction "closeDialog"
    linkCharacter: (player, character) ->
      @sendAction "linkCharacter", player, character
`export default LinkCharacterComponent`
