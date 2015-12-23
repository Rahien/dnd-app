`import Ember from 'ember'`

BlockControlsComponent = Ember.Component.extend
  actions:
    moveUp: ->
      @sendAction "moveUp", @get("block")
    moveDown: ->
      @sendAction "moveDown", @get("block")
    remove: ->
      @sendAction "remove", @get("block")
    addNew: ->
      @sendAction "addNew", @get("block")

`export default BlockControlsComponent`
