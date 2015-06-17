`import Ember from 'ember'`

CharController = Ember.Controller.extend
  init: ->
    @_super(arguments...)
  profBonus: Ember.computed "model.level", ->
    level = @get 'model.level'
    Math.floor(level/4)+2
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

  actions:
    save: ->
      model = @get 'model'
      Ember.$.ajax "/dnd/api/char/#{model._id}",
        method: "PUT"
        data: model.serialize()
        success: ->
          alert 'saved'
        error: ->
          alert 'could not save'
    delete: ->
      console.log "delete"

`export default CharController`
