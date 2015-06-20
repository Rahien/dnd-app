`import Ember from 'ember'`

UserService = Ember.Object.extend
  username: null
  password: null
  loggedIn: Ember.computed.notEmpty 'username'    

`export default UserService`
