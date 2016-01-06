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
    athletics: { value: "athleticsSkill", name: "athletics" }
    acrobatics: { value: "acrobaticsSkill", name: "acrobatics" }
    sleightOfHand: { value: "sleightOfHandSkill", name: "sleight of hand" }
    stealth: { value: "stealthSkill", name: "stealth" }
    arcana: { value: "arcanaSkill", name: "arcana" }
    history: { value: "historySkill", name: "history" }
    investigation: { value: "investigationSkill", name: "investigation" }
    nature: { value: "natureSkill", name: "nature" }
    religion: { value: "religionSkill", name: "religion" }
    animalHandling: { value: "animalHandlingSkill", name: "animal handling" }
    insight: { value: "insightSkill", name: "insight" }
    medicine: { value: "medicineSkill", name: "medicine" }
    perception: { value: "perceptionSkill", name: "perception" }
    survival: { value: "survivalSkill", name: "survival" }
    deception: { value: "deceptionSkill", name: "deception" }
    intimidate: { value: "intimidateSkill", name: "intimidate" }
    performance: { value: "performanceSkill", name: "performance" }
    persuasion: { value: "persuasionSkill", name: "persuasion" }
  availableProperties: Ember.computed 'properties', 'additionalProperties', ->
    properties = Ember.merge(Ember.merge({}, @get('properties')), @get('additionalProperties'))
  availablePropertiesList: Ember.computed 'availableProperties', ->
    available = @get('availableProperties')
    Object.keys(available).map (key) ->
      value = available[key]
      Ember.set(value, 'id', key)
      value
  visibleProperties: Ember.computed 'selectedProperties.[]', 'availableProperties', ->
    result = {}
    properties = @get 'availableProperties'
    @get('selectedProperties').map (key) ->
      result[key]=properties[key]
    result
  createDefaultOrder: ->
    @set 'defaultOrder', Ember.ArrayProxy.create
      content: Object.keys(@get('visibleProperties')).sort(naturalSort)
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
  sortedProperties: Ember.computed "visibleProperties.[]", "sortOrder", ->
    props = @get 'visibleProperties'
    sortOrder = @get 'sortOrder'
    result = []
    properties= sortOrder.map (key) ->
      value = props[key]
      if value
        Ember.set value, 'id', key
        result.push value
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
  sortedCharacters: Ember.computed "characters", "sortOrder", "visibleProperties.[]", ->
    order = @get 'selectedOrder'
    properties = @get 'visibleProperties'
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
    removeProperty: (prop) ->
      @get('selectedOrder').removeObject(prop.id)
      @get('defaultOrder').removeObject(prop.id)
      @get('selectedProperties').removeObject(prop.id)
      delete @get('additionalProperties')[prop.id]
      @notifyPropertyChange 'additionalProperties'
    requestProperty: ->
      @set 'showModal', true
      false
    addProperty: (property) ->
      if not property
        @set 'showModal', false
        return
      selected = @get 'selectedProperties'
      available = @get 'availablePropertiesList'
      found = available.findBy "value", property.value
      if found
        key = found.id
        if selected.contains key
          # ok it is already added
        else
          selected.pushObject(key)
          Ember.set found, 'selected', true
          @get('defaultOrder').pushObject(key)
          @get('selectedOrder').unshiftObject(key)
      else
        additional = @get 'additionalProperties'
        key = "custom"
        index = 0
        while additional["custom#{index}"]
          index++
        newId = "custom#{index}"
        property.id = newId
        property.selected = true
        additional[newId] = property
        selected.pushObject(newId)
        @get('defaultOrder').pushObject(newId)
        @get('selectedOrder').unshiftObject(newId)
        @notifyPropertyChange 'additionalProperties'
      @set 'showModal', false
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
