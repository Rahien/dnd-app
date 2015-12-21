`import Ember from 'ember'`

VoidRoute = Ember.Route.extend
  activate: ->
    @transitionTo 'chars'

`export default VoidRoute`
