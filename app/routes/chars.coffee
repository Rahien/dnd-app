`import Ember from 'ember'`
`import AuthRoute from '../utils/auth-route'`

CharsRoute = AuthRoute.extend
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
            @transitionTo('login')
          else
            reject error

`export default CharsRoute`
