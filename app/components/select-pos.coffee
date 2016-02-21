`import Ember from 'ember'`

SelectCharPosComponent = Ember.Component.extend
  classNames: "select-char-block"
  # findTypes: null, expected dto be list of find descriptions
  offsetTop: 100
  findType: 0
  duration: 1000
  findSpec: Ember.computed "findType", "findTypes", ->
    block = @get('findTypes')[@get('findType')]
  showExtra: Ember.computed.equal "findSpec.kind", "words"
  canConfirm: Ember.computed "findType", "title", ->
    @get('findSpec.kind') != "words" or @get('title')
  handleMove: (positionSpec) ->
    scrollTarget = null
    if not positionSpec
      @set 'selectFind', false
      return false
    if positionSpec.kind == "words"
      scrollTarget = Ember.$(":Contains(#{positionSpec.search}):not(:has(*))").filter("span, div, p")
    else
      scrollTarget = Ember.$(Ember.get(positionSpec, "finder"))
    if scrollTarget?[0]
      $('html, body').animate
        scrollTop: Math.max(0, scrollTarget.offset().top-@get('offsetTop'))
      , @get('duration')
    else
      @sendMessage 'error', 'Not found',
        autoClose: 3000
    @sendAction "confirmMove", positionSpec
  actions:
    confirm: ->
      if not @get 'canConfirm'
        return
      block = @get 'findSpec'
      if block.kind == "words"
        block.search = @get('title')
      @handleMove(block)
    cancel: ->
      @sendAction "confirmMove", undefined

`export default SelectCharPosComponent`
