`import Ember from 'ember'`
`import AuthRoute from '../utils/auth-route'`
`import SendMessage from '../mixins/send-message'`

CharsRoute = AuthRoute.extend SendMessage,
  model: ->
    new Ember.RSVP.Promise (resolve, reject) =>
      Ember.$.ajax "/dnd/api/chars",
        type: "GET"
        dataType: "json"
        success: (response) ->
          resolve(response)
        error: (error) =>
          reject error

`export default CharsRoute`
