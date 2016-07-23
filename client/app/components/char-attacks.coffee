`import Ember from 'ember'`

CharAttacksComponent = Ember.Component.extend
  classNames: ["attacks"]
  attacks: Ember.computed 'char.attacks', ->
    Ember.ArrayProxy.create
      content: @get('char.attacks')
  actions:
    deleteAttack: (attack) ->
      @get('attacks').removeObject attack
    createAttack: (attack) ->
      @get('attacks').addObject
        name: "attack name"
        attack: "Str"
        damage: "1d6"
        def: "AC"
        range: ""
        type: "slashing"
      

`export default CharAttacksComponent`
