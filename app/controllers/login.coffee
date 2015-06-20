`import Ember from 'ember'`

LoginController = Ember.Controller.extend
  badUser: Ember.computed 'username', ->
    user = @get 'username'
    (not user) or user.length < 1
  badPwd: Ember.computed 'password', ->
    pwd = @get 'password'
    (not pwd) or pwd.length < 1
  username: Ember.computed.alias 'user.username'
  password: Ember.computed.alias 'user.password'
  actions:
    login: ->
      if @get('badUser') or @get('badPwd')
        alert 'please fill in both a username and a password'
        return

      previous = @get 'attemptedTransition'
      if previous
        previous.retry();
        this.set 'attemptedTransition', null
      else
        this.transitionToRoute('chars')

`export default LoginController`
