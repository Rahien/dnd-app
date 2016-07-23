`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`

RegisterController = Ember.Controller.extend SendMessage,
  badUser: Ember.computed 'username', ->
    user = @get 'username'
    (not user) or user.length < 1
  badPwd: Ember.computed 'password', ->
    pwd = @get 'password'
    (not pwd) or pwd.length < 1
  badPwd2: Ember.computed 'password', 'passwordAgain', ->
    pwd = @get 'password'
    pwd2 = @get 'passwordAgain'
    not (pwd == pwd2)
  showInfo: false    
  actions:
    toggleInfo: ->
      @set 'showInfo', not @get('showInfo')
    register: ->
      if @get('badUser') or @get('badPwd') or @get('badPwd2')
        @sendMessage "error", "please fix the errors above, you need a username and your passwords have to match",
          autoClose: 5000
      else
        data =
          data:
            type: "accounts"
            attributes:
              username: @get 'username'
              nickname: @get 'username'
              password: @get 'password'
              "password-confirmation": @get 'passwordAgain'

        Ember.$.ajax "/accounts",
          type: "POST"
          contentType: "application/vnd.api+json"
          data: JSON.stringify(data)
          success: (result) =>
            @transitionToRoute('index')
          error: (error) =>
            @sendMessage 'error', 'Sorry could not register you at the server, please contact your administrator'

`export default RegisterController`
