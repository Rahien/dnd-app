`import Ember from 'ember'`
`import AuthRoute from '../utils/auth-route'`

IndexRoute = AuthRoute.extend
  model: ->
    new Ember.RSVP.Promise (resolve, reject) =>
      Ember.$.ajax "/dnd/api/settings",
        type: "GET"
        dataType: "json"
        success: (response) ->
          resolve(response)
        error: (error) =>
          reject error


`export default IndexRoute`
