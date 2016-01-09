`import Ember from 'ember'`

ApplicationController = Ember.Controller.extend
  session: Ember.inject.service('session')
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
  homeShow: Ember.computed 'currentRouteName', ->
    @get('currentRouteName') != "index"
  showButtons: false
  hasMessages: Ember.computed.notEmpty 'messages'
  removeMessage: (message) ->
    @get('messages').removeObject message
  actions:
    showButtons: ->
      @set 'showButtons', not @get('showButtons')
    toHome: ->
      @transitionToRoute 'index'
    toggleMenu: ->
      @set 'showMenu', (not @get('showMenu'))
      false
    logout: ->
      @get('session').invalidate()
      @transitionToRoute 'login'
    removeMessage: (message) ->
      @removeMessage(message)
`export default ApplicationController`
