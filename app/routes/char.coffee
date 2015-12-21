`import Ember from 'ember'`
`import Char from '../models/char'`
`import AuthRoute from '../utils/auth-route'`
`import SendMessage from '../mixins/send-message'`

CharRoute = AuthRoute.extend SendMessage,
  model: (params) ->
    new Ember.RSVP.Promise (resolve,reject) =>
      Ember.$.ajax "/dnd/api/char/#{params.id}",
        type: "GET"
        dataType: "json"
        success: (result) ->
          resolve(Char.create(result))
        error: (error) =>
          reject error
`export default CharRoute`
