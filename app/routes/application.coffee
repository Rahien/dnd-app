`import Ember from 'ember'`

LoginRoute = Ember.Route.extend
  actions:
    showMessage: (message) ->
      messages = @get('controller.messages')
      messages.addObject message

      if message.type != "error" or message.autoClose
        Ember.run.later @get('controller'), (-> @removeMessage(message)), (message.autoClose or 5000)
      false

`export default LoginRoute`
