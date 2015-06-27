`import Ember from 'ember'`

ApplicationController = Ember.Controller.extend
  init: ->
    @_super(arguments...)
    @set 'showMenu', true
    @set 'messages', Ember.ArrayProxy.create
      content: []

  messages: null
  menuShow: Ember.computed 'showMenu', 'currentRouteName', ->
    if @get('currentRouteName') == "login"
      return "hide"
    if @get('showMenu')
      "show"
  hasMessages: Ember.computed.notEmpty 'messages'
  removeMessage: (message) ->
    @get('messages').removeObject message
  actions:
    toggleMenu: ->
      @set 'showMenu', (not @get('showMenu'))
    logout: ->
      @transitionToRoute 'login'
    removeMessage: (message) ->
      @removeMessage(message)
`export default ApplicationController`
