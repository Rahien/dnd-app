`import Ember from 'ember'`

CharController = Ember.Controller.extend
  profBonus: Ember.computed "model.level", ->
    level = @get 'model.level'
    Math.floor(level/4)+2
  stats: Ember.computed "model.stats", ->
    stats = @get('model.stats')
    Ember.keys(stats).map (key) ->
      label: key
      value: stats[key]
  strmod: Ember.computed "model.abilities.str", ->
    @mod("str")
  dexmod: Ember.computed "model.abilities.dex", ->
    @mod("dex")
  conmod: Ember.computed "model.abilities.con", ->
    @mod("con")
  intmod: Ember.computed "model.abilities.int", ->
    @mod("int")
  wismod: Ember.computed "model.abilities.wis", ->
    @mod("wis")
  chamod: Ember.computed "model.abilities.cha", ->
    @mod("cha")
  mod: (ability) ->
    value = @get "model.abilities.#{ability}"
    Math.floor((value-10)/2)
  load: Ember.computed "model.gear.@each.weight", ->
    gear = @get 'model.gear'
    weight = 0
    gear.map (item) ->
      weight+=item.weight
  carry: Ember.computed "model.abilities.str", ->
    str = @get 'model.abilities.str'
    str*15
  pushOrDrag: Ember.computed "model.abilities.str", ->
    str = @get 'model.abilities.str'
    str*30

`export default CharController`
