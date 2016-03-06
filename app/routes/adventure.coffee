`import Ember from 'ember'`
`import Adventure from '../models/adventure'`
`import AuthRoute from '../utils/auth-route'`

AdventureRoute = AuthRoute.extend
  activate: ->
    # Hack: need to take this way out... security restriction on fake click of input
    # click has to be sent from within event handling context (o-m-g)
    # don't have didInsertElement... :(
    Ember.run.later ( ->
      Ember.$(".button.upload").click ->
         Ember.$(".uploadInput").click();
    ), 500
  model: (params) ->
    new Ember.RSVP.Promise (resolve,reject) =>
      Ember.$.ajax "/dnd/api/adventure/#{params.id}",
        type: "GET"
        dataType: "json"
        success: (result) ->
          resolve(Adventure.create(result))
        error: (error) =>
          reject error


`export default AdventureRoute`
