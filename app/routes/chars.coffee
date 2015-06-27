`import Ember from 'ember'`
`import AuthRoute from '../utils/auth-route'`
`import SendMessage from '../mixins/send-message'`

CharsRoute = AuthRoute.extend SendMessage,
  model: ->
    new Ember.RSVP.Promise (resolve, reject) =>
      Ember.$.ajax "/dnd/api/chars",
        type: "GET"
        dataType: "json"
        username: @get 'user.username'
        password: @get 'user.password'
        success: (response) ->
          resolve(response)
        error: (error) =>
          if error.status == 401
            @sendMessage 'error', 'Access denied!',
              autoClose: 5000
            @transitionTo('login')
          else
            @sendMessage 'error', 'Sorry, could not get the list of characters from the server'
            reject error

`export default CharsRoute`
