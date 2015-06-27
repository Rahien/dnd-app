`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`

LoginController = Ember.Controller.extend SendMessage,
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
        @sendMessage 'error', 'please fill in both a username and a password',
          autoClose: 5000
        return

      previous = @get 'attemptedTransition'
      if previous
        previous.retry();
        this.set 'attemptedTransition', null
      else
        this.transitionToRoute('chars')
    register: ->
      @transitionToRoute 'register'

`export default LoginController`
