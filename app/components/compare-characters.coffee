`import Ember from 'ember'`
`import naturalSort from 'npm:javascript-natural-sort'`

CompareCharactersComponent = Ember.Component.extend
  init: ->
    @_super(arguments...)
    @createDefaultOrder()
  properties:
    class: Ember.Object.create { value: "class", name: "class"}
    race: Ember.Object.create  { value: "race", name: "race"}
    level: Ember.Object.create { value: "level", name: "level" }
    strength: Ember.Object.create { value: "abilities.str", name: "strength" }
    dexterity: Ember.Object.create { value: "abilities.dex", name: "dexterity" }
    constitution: Ember.Object.create { value: "abilities.con", name: "constitution" }
    intelligence: Ember.Object.create { value: "abilities.int", name: "intelligence" }
    wisdom: Ember.Object.create { value: "abilities.wis", name: "wisdom" }
    charisma: Ember.Object.create { value: "abilities.cha", name: "charisma" }
    initiative: Ember.Object.create { value: "initiative", name: "initiative" }
    hp: Ember.Object.create { value: "hp.current", name: "HP" }
    hpTot: Ember.Object.create { value: "hp.total", name: "HP total" }
    hd: Ember.Object.create { value: "hd.total", name: "HD" }
    ac: Ember.Object.create { value: "ac.armor", name: "AC"}
    acNoArmor: Ember.Object.create { value: "ac.noArmor", name: "AC (no armor)"}
  createDefaultOrder: ->
    @set 'defaultOrder', Ember.ArrayProxy.create
      content: Object.keys(@get('properties')).sort(naturalSort)
    @set 'selectedOrder', Ember.ArrayProxy.create
      content: []
  sortOrder: Ember.computed 'defaultOrder', 'selectedOrder.[]', ->
    def = @get 'defaultOrder'
    selected = @get 'selectedOrder'

    result = Ember.ArrayProxy.create
      content: def.get('content').concat([])

    reversed = selected.get('content').concat([])
    reversed.reverse()
    reversed.map (key) ->
      result.removeObject(key)
      result.unshiftObject(key)
    result      
  sortedProperties: Ember.computed "properties", "sortOrder", ->
    props = @get 'properties'
    sortOrder = @get 'sortOrder'
    properties= sortOrder.map (key) ->
      result = props[key]
      result.id = key
      result
  sortOn: (prop) ->
    currentOrder = @get 'selectedOrder'
    first = currentOrder.objectAt(0)
    currentOrder.removeObject(prop.id)
    if first != prop.id
      currentOrder.unshiftObject(prop.id)
      prop.set('selected', true)
    else
      prop.set('selected', false)
  naturalSortBy: (propertyPath) ->
    (left, right) ->
      naturalSort(Ember.get(left, propertyPath), Ember.get(right, propertyPath))
  sortedCharacters: Ember.computed "characters", "sortOrder", "properties", ->
    order = @get 'selectedOrder'
    properties = @get 'properties'
    sortValues = order.map (key) ->
      properties[key].get('value')
    target = @get('characters').concat([])
    sorter = null
    index = 0
    while index < sortValues.length
      if not sorter
        sorter = firstBy @naturalSortBy(sortValues[index])
      else
        sorter = sorter.thenBy @naturalSortBy(sortValues[index])
      index++
    if sorter
      target.sort(sorter).reverse()
    target
  actions:
    sortOn: (prop) ->
      @sortOn prop
    unlinkCharacter: (char) ->
      @sendAction "unlinkCharacter", char

`export default CompareCharactersComponent`
