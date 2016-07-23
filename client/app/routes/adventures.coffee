`import Ember from 'ember'`
`import AuthRoute from '../utils/auth-route'`

AdventuresRoute = AuthRoute.extend
  model: ->
    new Ember.RSVP.Promise (resolve, reject) =>
      Ember.$.ajax "/dnd/api/adventures",
        type: "GET"
        dataType: "json"
        success: (response) ->
          resolve(response)
        error: (error) =>
          reject error

`export default AdventuresRoute`
