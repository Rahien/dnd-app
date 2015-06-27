`import Ember from 'ember'`

SendMessageMixin = Ember.Mixin.create
  sendMessage: (type, message, options) ->
    fun = @sendAction or @send
    options = options or {}
    options.type ||= type
    options.message ||= message
    fun.call this, "showMessage", options

`export default SendMessageMixin`
