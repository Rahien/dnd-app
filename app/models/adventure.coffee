`import Ember from 'ember'`
`import Char from './char'`
`import Monster from './monster'`

Adventure = Ember.Object.extend
  serialize: ->
    simplify = JSON.parse(JSON.stringify(this))
    (simplify.owner = simplify.owner._id) if simplify.owner
    simplify.selectedProperties = @get 'selectedProperties.content'
    Object.keys(simplify.additionalProperties).map (key) ->
      simplify.additionalProperties[key].selected = false
    simplify
  init: ->
    @_super(arguments...)
    chars = @get 'chars'
    if @get 'selectedProperties'
      @set 'selectedProperties', Ember.ArrayProxy.create content: @get('selectedProperties')
    else
      @set 'selectedProperties', Ember.ArrayProxy.create content: ["initiative", "hp", "ac", "gold"]
    unless @get 'additionalProperties'
      @set 'additionalProperties', {}

    if @get 'edit'
      newChars = chars.map (char) ->
        Char.create(char)
      chars.splice.apply(chars,[0,Number.MAX_VALUE].concat(newChars))
      monsters = @get('monsters') or []
      newMonsters = monsters.map (monster) ->
        Monster.create(monster)
      monsters.splice.apply(monsters,[0,Number.MAX_VALUE].concat(newMonsters))

Adventure.getDefault = ->
  Adventure.create 
    name: "Once more unto the breach"
    date: Date.now()
    chars: []
    monsters: []
    dmNotes: ""

`export default Adventure`
