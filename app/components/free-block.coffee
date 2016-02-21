`import Ember from 'ember'`

FreeBlockComponent = Ember.Component.extend
  hasTitle: Ember.computed.notEmpty 'title'
  classNames: "free-block"
  classNameBindings: ["editing:editing"]
  showPlaceholder: Ember.computed "placeholder", "noContent", ->
    @get('placeholder') and @get('noContent')
  noContent: Ember.computed.empty "content"
  init: ->
    @_super(arguments...)
    @set 'editing', false

  markdownOptions:
    extensions: ['table']

  actions:
    toggleEdit: ->
      @set 'editing', not @get('editing')


`export default FreeBlockComponent`
