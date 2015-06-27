`import Ember from 'ember'`

RegisterController = Ember.Controller.extend

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
        alert "please fix the errors above, you need a username and your passwords have to match"
      else
        data =
          username: @get 'username'
          password: @get 'password'

        Ember.$.ajax "/dnd/api/register",
          type: "POST"
          dataType: "json"
          contentType: "application/json; charset=utf-8"
          data: JSON.stringify(data)
          success: (result) ->
            alert JSON.stringify(result)
          error: (error) ->
            alert JSON.stringify(error)

`export default RegisterController`
