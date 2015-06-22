`import Ember from 'ember'`

ApplicationController = Ember.Controller.extend
  init: ->
    @_super(arguments...)
    @set 'showMenu', true

  menuShow: Ember.computed 'showMenu', 'currentRouteName', ->
    if @get('currentRouteName') == "login"
      return "hide"
    if @get('showMenu')
      "show"
  actions:
    toggleMenu: ->
      @set 'showMenu', (not @get('showMenu'))
    logout: ->
      @transitionToRoute 'login'

`export default ApplicationController`
