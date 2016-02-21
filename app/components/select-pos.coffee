`import Ember from 'ember'`

SelectCharPosComponent = Ember.Component.extend
  classNames: "select-char-block"
  # findTypes: null, expected dto be list of find descriptions
  findType: 0
  findSpec: Ember.computed "findType", "findTypes", ->
    block = @get('findTypes')[@get('findType')]
  showExtra: Ember.computed.equal "findSpec.kind", "words"
  canConfirm: Ember.computed "findType", "title", ->
    @get('findSpec.kind') != "words" or @get('title')
  actions:
    confirm: ->
      if not @get 'canConfirm'
        return
      block = @get 'findSpec'
      if block.kind == "words"
        block.search = @get('title')
      @sendAction "confirmMove", block
    cancel: ->
      @sendAction "confirmMove", undefined


`export default SelectCharPosComponent`
