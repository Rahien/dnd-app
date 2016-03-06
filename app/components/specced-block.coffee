`import Ember from 'ember'`

SpeccedBlockComponent = Ember.Component.extend
  title: "Block"
  classNames: "free-block"
  # spec of what to show in this block
  spec: null

  title: Ember.computed.alias "spec.title"
  classNameBindings: "spec.content"
  
  init: ->
    @_super(arguments...)
    @set 'editing', false
    @set 'contentBinding', Ember.bind(this,"content", "char.#{@get('spec.content')}")

  markdownOptions:
    extensions: ['table']

  willDestroy: ->
    @_super(arguments...)
    @get('contentBinding').disconnect(@get('contentBinding'))
    @set('contentBinding', null)

  actions:
    toggleEdit: ->
      @set 'editing', not @get('disabled') and not @get('editing')


`export default SpeccedBlockComponent`
