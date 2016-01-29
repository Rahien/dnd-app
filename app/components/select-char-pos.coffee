`import Ember from 'ember'`

SelectCharPosComponent = Ember.Component.extend
  classNames: "select-char-block"
  findTypes: Ember.computed 'char', ->
    blocks = @get('char.charBlocks.left.content').concat(@get('char.charBlocks.right.content'))
    foundSpells = false
    blocks.push { kind: "words", title: "Words" }
    blocks.map (block, index) ->
      if not Ember.get(block, 'title')
        Ember.set(block, 'title', Ember.get(block, 'kind').replace("char-", ""))
      block.index = index
      block
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
