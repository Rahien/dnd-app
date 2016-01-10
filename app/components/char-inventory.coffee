`import Ember from 'ember'`

CharInventoryComponent = Ember.Component.extend
  classNames: ["gear inventory"]
       
  load: Ember.computed "char.gear.@each.weight", ->
    gear = @get 'char.gear'
    weight = 0
    gear.map (item) ->
      w = parseFloat(Ember.get item, 'weight')
      weight+= (if isNaN(w) then 0 else w)
    weight
  gear: Ember.computed "char.gear", ->
    Ember.ArrayProxy.create
      content: @get "char.gear"
  actions:
    removeItem: (item) ->
      gear = @get 'gear'
      gear.removeObject item
    createItem: ->
      @get('gear').addObject
        name: "item name"
        price: 0
        weight: 0
        notes: ""

`export default CharInventoryComponent`
