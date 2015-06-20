`import Ember from 'ember'`
`import Char from '../models/char'`
`import AuthRoute from '../utils/auth-route'`

CharRoute = AuthRoute.extend
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
          else if typeof error == "string"
            alert(error)
          else
            alert(JSON.stringify(error))

`export default CharRoute`
