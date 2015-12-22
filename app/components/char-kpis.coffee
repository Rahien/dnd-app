`import Ember from 'ember'`

CharKpisComponent = Ember.Component.extend
  classNames: "char-kpis"
  strmod: Ember.computed "model.abilities.str", ->
    @mod("str")
  dexmod: Ember.computed "char.abilities.dex", ->
    @mod("dex")
  conmod: Ember.computed "char.abilities.con", ->
    @mod("con")
  intmod: Ember.computed "char.abilities.int", ->
    @mod("int")
  wismod: Ember.computed "char.abilities.wis", ->
    @mod("wis")
  chamod: Ember.computed "char.abilities.cha", ->
    @mod("cha")
  mod: (ability) ->
    value = @get "char.abilities.#{ability}"
    Math.floor((value-10)/2)

`export default CharKpisComponent`
