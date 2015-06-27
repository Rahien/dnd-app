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
        username: @get 'user.username'
        password: @get 'user.password'
        success: (result) ->
          resolve(Char.create(result))
        error: (error) ->
          if error.status == 401
            @transitionToRoute 'login'
          else
            @sendMessage 'error', "Sorry, could not fetch the character from the server, contact your administrator"

`export default CharRoute`
