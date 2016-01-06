`import Ember from 'ember'`
`import naturalSort from 'npm:javascript-natural-sort'`
`import SendMessage from '../mixins/send-message'`

CompareCharactersComponent = Ember.Component.extend SendMessage,
  init: ->
    @_super(arguments...)
    @createDefaultOrder()
  properties:
    class: { value: "class", name: "class"}
    race:  { value: "race", name: "race"}
    level: { value: "level", name: "level" }
    strength: { value: "abilities.str", name: "strength" }
    dexterity: { value: "abilities.dex", name: "dexterity" }
    constitution: { value: "abilities.con", name: "constitution" }
    intelligence: { value: "abilities.int", name: "intelligence" }
    wisdom: { value: "abilities.wis", name: "wisdom" }
    charisma: { value: "abilities.cha", name: "charisma" }
    initiative: { value: "initiative", name: "initiative" }
    hp: { value: "hp.current", name: "HP" }
    hpTot: { value: "hp.total", name: "HP total" }
    hd: { value: "hd.total", name: "HD" }
    ac: { value: "ac.armor", name: "AC"}
    acNoArmor: { value: "ac.noArmor", name: "AC (no armor)"}
    gold: { value: "gold", name: "gold"}
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
      Ember.set(prop,'selected', true)
    else
      Ember.set(prop,'selected', false)
  naturalSortBy: (propertyPath) ->
    (left, right) ->
      naturalSort(Ember.get(left, propertyPath), Ember.get(right, propertyPath))
  sortedCharacters: Ember.computed "characters", "sortOrder", "properties", ->
    order = @get 'selectedOrder'
    properties = @get 'properties'
    sortValues = order.map (key) ->
      Ember.get(properties[key], 'value')
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
    refreshCharacter: (char) ->
      Ember.$.ajax "/dnd/api/char/#{char._id}",
        type: "GET"
        dataType: "json"
        success: (result) =>
          char.setProperties(result)
          @sendMessage 'goodstuff', "refreshed Character"
        error: (error) =>
          @sendMessage 'error', "Could not refresh character: #{error.responseText}"


`export default CompareCharactersComponent`
