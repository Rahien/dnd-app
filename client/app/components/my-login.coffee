`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`
`import MuLogin from 'ember-mu-login/mixins/mu-login'`

MyLoginComponent = Ember.Component.extend SendMessage, MuLogin,
  classNames: "login"
  session: Ember.inject.service('session')
  badUser: Ember.computed 'nickname', ->
    user = @get 'nickname'
    (not user) or user.length < 1
  badPwd: Ember.computed 'password', ->
    pwd = @get 'password'
    (not pwd) or pwd.length < 1
  nickname: ""
  password: ""
  actions:
    trylogin: ->
      if @get('badUser') or @get('badPwd')
        @sendMessage 'error', 'please fill in both a username and a password',
          autoClose: 5000
        return
      @sendAction 'login'

`export default MyLoginComponent`
