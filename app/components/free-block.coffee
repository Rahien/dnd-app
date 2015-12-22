`import Ember from 'ember'`

FreeBlockComponent = Ember.Component.extend
  title: "Block"
  classNames: "free-block"
  classNameBindings: ["editing:editing"]

  init: ->
    @_super(arguments...)
    @set 'editing', false

  markdownOptions:
    extensions: ['table']

  actions:
    toggleEdit: ->
      @set 'editing', not @get('editing')


`export default FreeBlockComponent`
