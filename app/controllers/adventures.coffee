`import Ember from 'ember'`
`import Adventure from '../models/adventure'`
`import SendMessage from '../mixins/send-message'`

AdventuresController = Ember.Controller.extend SendMessage,
  adventures: Ember.computed 'model', ->
    adv = @get('model').concat([])
    result = adv.sort (one,two) ->
      if one.date < two.date then -1 else 1
    result.map (item) ->
      item.date = new Date(item.date)
  hasAdventures: Ember.computed.notEmpty "adventures"
  actions:
    openAdventure: (adventure) ->
      @transitionToRoute 'adventure', adventure._id
    newAdventure: ->
      def = Adventure.getDefault()
      Ember.$.ajax "/dnd/api/adventures",
        type: "POST"
        contentType: "application/json; charset=utf-8"
        data: JSON.stringify(def)
        success: (result) =>
          @transitionToRoute 'adventure', result.id
        error: (error) =>
          @sendMessage 'error', "Sorry, could not create the new adventure on the server, contact your administrator.\nServer reply was:\n#{error.responseText}"

`export default AdventuresController`
