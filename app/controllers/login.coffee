`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`

LoginController = Ember.Controller.extend SendMessage,
  session: Ember.inject.service('session')
  init: ->
    @_super(arguments...)
    if @get 'session.isAuthenticated'
      @doTransition()
  badUser: Ember.computed 'username', ->
    user = @get 'username'
    (not user) or user.length < 1
  badPwd: Ember.computed 'password', ->
    pwd = @get 'password'
    (not pwd) or pwd.length < 1
  username: ""
  password: ""
  doTransition: ->
    previous = @get 'attemptedTransition'
    if previous
      previous.retry();
      this.set 'attemptedTransition', null
    else
      this.transitionToRoute('chars')
  actions:
    login: ->
      if @get('badUser') or @get('badPwd')
        @sendMessage 'error', 'please fill in both a username and a password',
          autoClose: 5000
        return
      session = @get 'session'
      session.authenticate('authenticator:oauth2', @get('username'), @get('password')).then( =>
        session.authorize 'authorizer:oauth2', (headerName, headerValue) =>
          headers = {}
          headers[headerName] = headerValue
          Ember.$.ajaxSetup(headers: headers)
          @doTransition()
      ).catch (error) =>
        @sendMessage 'error', "could not log in, #{error.error or error}",
          autoClose: 5000
    register: ->
      @transitionToRoute 'register'

`export default LoginController`
