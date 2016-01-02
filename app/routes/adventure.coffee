`import Ember from 'ember'`
`import Adventure from '../models/adventure'`
`import AuthRoute from '../utils/auth-route'`

AdventureRoute = AuthRoute.extend
  model: (params) ->
    new Ember.RSVP.Promise (resolve,reject) =>
      Ember.$.ajax "/dnd/api/adventure/#{params.id}",
        type: "GET"
        dataType: "json"
        success: (result) ->
          resolve(Char.create(result))
        error: (error) =>
          reject error


`export default AdventureRoute`
