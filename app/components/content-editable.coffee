`import Ember from 'ember'`

ContentEditableComponent = Ember.Component.extend
  tagName: 'div'
  attributeBindings: ['contenteditable']
  editable: true
  contenteditable: Ember.computed 'editable', ->
  	editable = @get('editable');

  	if editable then 'true' else undefined

  focusOut: ->
    Ember.run.later =>
      lastValue = @get 'lastValue'
      if lastValue and not Ember.isEmpty lastValue
      	@set 'value', lastValue

  keyUp: (event) ->
  	@set 'lastValue', (@$().text() or " ")


`export default ContentEditableComponent`
