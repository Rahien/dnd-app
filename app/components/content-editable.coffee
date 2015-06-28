`import Ember from 'ember'`

ContentEditableComponent = Ember.Component.extend
  tagName: 'div'
  attributeBindings: ['contenteditable']
  editable: true
  contenteditable: Ember.computed 'editable', ->
  	editable = @get('editable');

  	if editable then 'true' else undefined

  focusOut: ->
    Ember.run.later this, (->
      @updateLastValue()
      lastValue = @get 'lastValue'
      if lastValue and not Ember.isEmpty lastValue
      	@set 'value', lastValue
    )
  updateLastValue: ->
    @set 'lastValue', (@$().text() or " ")
  keyUp: (event) ->
  	Ember.run.debounce this, @updateLastValue, 100
    

`export default ContentEditableComponent`
