`import Ember from 'ember'`

ApplicationController = Ember.Controller.extend
  session: Ember.inject.service('session')
  init: ->
    @_super(arguments...)
    @set 'messages', Ember.ArrayProxy.create
      content: []

  messages: null
  menuShow: Ember.computed 'currentRouteName', ->
    if (@get('currentRouteName') == "login") or (@get('currentRouteName') == "register")
      return "hide"
    else
      "show"
  homeShow: Ember.computed 'currentRouteName', ->
    @get('currentRouteName') != "index"
  showButtons: false
  hasMessages: Ember.computed.notEmpty 'messages'
  removeMessage: (message) ->
    @get('messages').removeObject message
  actions:
    showButtons: (value) ->
      if Ember.isNone(value)
        @set 'showButtons', not @get('showButtons')
      else
        @set 'showButtons', value
      false

    toHome: ->
      @transitionToRoute 'index'
    logout: ->
      @get('session').invalidate()
      @transitionToRoute 'login'
    removeMessage: (message) ->
      @removeMessage(message)
`export default ApplicationController`
