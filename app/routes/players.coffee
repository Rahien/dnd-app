`import Ember from 'ember'`

PlayersRoute = Ember.Route.extend
  model: ->
    new Ember.RSVP.Promise (resolve, reject) =>
      Ember.$.ajax "/dnd/api/players",
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

`export default PlayersRoute`
