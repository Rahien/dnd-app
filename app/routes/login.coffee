`import Ember from 'ember'`

LoginRoute = Ember.Route.extend
  onActivate: Ember.on 'activate', ->
    @set 'user.username', null    
    @set 'user.password', null    

`export default LoginRoute`
