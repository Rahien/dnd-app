`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`

CharController = Ember.Controller.extend SendMessage,
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
        data: JSON.stringify(model.serialize())
        contentType: "application/json; charset=utf-8"
        username: @get 'user.username'
        password: @get 'user.password'
        success: =>
          @sendMessage 'goodstuff', 'Saved character'
        error: =>
          @sendMessage 'error', 'Could not save character!'
    delete: ->
      model = @get 'model'
      Ember.$.ajax "/dnd/api/char/#{model._id}",
        method: "DELETE"
        username: @get 'user.username'
        password: @get 'user.password'
        success: =>
          @transitionToRoute 'chars'
        error: =>
          @sendMessage 'error', "Could not remove character!"
    toCharacters: ->
      @transitionToRoute 'chars'
    handleUpload: (result) ->
      @set 'model.image', "/dnd/api/image/#{result}"
    clickImage: ->
      Ember.$('.character .image input').click()

`export default CharController`
