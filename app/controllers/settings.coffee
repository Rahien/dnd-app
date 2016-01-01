`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`

SettingsController = Ember.Controller.extend SendMessage,
  badUser: Ember.computed 'model.username', ->
    user = @get 'model.username'
    (not user) or user.length < 1
  badOldPwd: Ember.computed 'oldPassword', ->
    pwd = @get 'oldPassword'
    (not pwd) or pwd.length < 1
  badPwd: Ember.computed 'newPassword', ->
    pwd = @get 'newPassword'
    (not pwd) or pwd.length < 1
  badPwd2: Ember.computed 'newPassword', 'newPasswordAgain', ->
    pwd = @get 'newPassword'
    pwd2 = @get 'newPasswordAgain'
    not (pwd == pwd2)
  actions:
    back: ->
      @transitionToRoute 'index'
    updateUser: ->
      if @get('badUser') or @get('badPwd') or @get('badPwd2') or @get('badOldPwd')
        @sendMessage "error", "please fix the errors above, you need a username and your passwords have to match",
          autoClose: 5000
      else
        data =
          name: @get 'model.username'
          oldPwd: @get 'oldPassword'
          newPwd: @get 'newPassword'

        Ember.$.ajax "/dnd/api/player/#{@get('model._id')}",
          type: "PUT"
          contentType: "application/json; charset=utf-8"
          data: JSON.stringify(data)
          success: (result) =>
            @transitionToRoute('index')
          error: (error) =>
            @sendMessage 'error', 'Sorry could not update your player at the server, please contact your administrator'



`export default SettingsController`
