`import Ember from 'ember'`
`import DS from 'ember-data';`

Char = DS.Model.extend
  name: DS.attr()
  description: DS.attr()
  race: DS.attr()
  className: DS.attr()
  level: DS.attr('number')
  player: DS.belongsTo 'player', inverse: null
  items: DS.hasMany 'item', inverse: null
  spells: DS.hasMany 'spell', inverse: null
  
  init: ->
    @_super(arguments...)
    skills = @get 'skillNames'
    Object.keys(skills).map (key) =>
      attribute = skills[key]
      skillName = key.replace(/([A-Z])/g, ' $1').toLowerCase()
      skillKey = "#{key}Skill"
      if this[skillKey]
        delete this[skillKey]
      computed = Ember.computed "profBonus", "profs.skills", "attr.#{attribute}", ->
        bonus = @get "#{attribute}mod"
        if @get('profs.skills')?.toLowerCase()?.indexOf(skillName) >= 0
          bonus += @get('profBonus')
        bonus
      Ember.defineProperty this, skillKey, computed
  skillNames:
    athletics: "str"
    acrobatics: "dex"
    sleightOfHand: "dex"
    stealth: "dex"
    arcana: "int"
    history: "int"
    investigation: "int"
    nature: "int"
    religion: "int"
    animalHandling: "wis"
    insight: "wis"
    medicine: "wis"
    perception: "wis"
    survival: "wis"
    deception: "cha"
    intimidate: "cha"
    performance: "cha"
    persuasion: "cha"
  carry: Ember.computed "abilities.str", ->
    str = @get 'abilities.str'
    str*15
  pushOrDrag: Ember.computed "abilities.str", ->
    str = @get 'abilities.str'
    str*30
  profBonus: Ember.computed "level", ->
    level = @get 'level'
    Math.floor((level-1)/4)+2
  serialize: ->
    simplify = JSON.stringify(this)
    json = JSON.parse(simplify)
    json.charBlocks.left = @get('charBlocks.left.content')
    json.charBlocks.right = @get('charBlocks.right.content')
    json
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

Char.getDefault = (store) ->
  store.createRecord 'character',
    name: "Unnamed hero"
    description: "Nothing is known about this hero yet, it has yet to write its own history..."
    race: "Human"
    level: 1
    className: "Fighter"

`export default Char`
