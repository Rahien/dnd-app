`import DS from 'ember-data'`

Monster = Ember.Object.extend {
  serialize: ->
    simplify = JSON.parse(JSON.stringify(this))
    delete simplify.owner
    simplify
  hasTraits: Ember.computed.notEmpty 'traits'
  hasActions: Ember.computed.notEmpty 'actions'
  hasLegendary: Ember.computed.notEmpty 'legendary'
  hasReactions: Ember.computed.notEmpty 'reactions'
  strmod: Ember.computed "abilities.str", ->
    @mod("str")
  dexmod: Ember.computed "abilities.dex", ->
    @mod("dex")
  conmod: Ember.computed "abilities.con", ->
    @mod("con")
  intmod: Ember.computed "abilities.int", ->
    @mod("int")
  wismod: Ember.computed "abilities.wis", ->
    @mod("wis")
  chamod: Ember.computed "abilities.cha", ->
    @mod("cha")
  mod: (ability) ->
    value = @get "abilities.#{ability}"
    Math.floor((value-10)/2)
}

Monster.getDefault = ->
  Monster.create
    name: "A rat in the basement"
    attacks: []
    abilities:
      str: 16
      dex: 16
      con: 14
      int: 8
      wis: 12
      cha: 4
    size: "Small"
    type: "beast"
    alignment: "chaotic neutral"
    ac: 12
    hp: "8 (1d8 + 3)"
    speed: '30 ft, burrow 10 ft'
    challenge: '1/8'
    stats: [
      { label: "skills", value: "perception, stealth +1" },
      { label: "senses", value: "darkvision, 60 ft." },
      { label: "languages", value: "-" }
    ]
    traits: ""
    actions: ""
    legendary: ""
    reactions: ""


`export default Monster`
