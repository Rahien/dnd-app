`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`
`import Char from '../models/char'`

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
  filename: Ember.computed "model.name", ->
    name = @get 'model.name'
    name.replace(/[^a-z0-9]/gi, '_').toLowerCase();
  doSave: ->
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
  actions:
    save: ->
      @doSave()
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
    upload: ->
      Ember.$('#buttons input.uploadInput').click()
    doUpload: ->
      input = Ember.$('#buttons input.uploadInput')[0]
      file = input.files[0]
      onError = =>
        @sendMessage 'error', "Sorry, could not read the file"
      if file
        reader = new FileReader()
        reader.readAsText(file, "UTF-8")
        reader.onload = (evt) =>
          try
            object = JSON.parse(evt.target.result)
            model = @get 'model'
            id = model._id
            rev = model._rev
            object._id = id
            object._rev = rev
            @set 'model', Char.create(object)
            
            @doSave()
          catch e
            onError()
        reader.onerror = onError
        try
          input.value = ''
          if input.value
            input.type = "text"
            input.type = "file"
        catch e
          "tried our best to clear the input"
    download: ->
      model = @get 'model'
      Ember.$('#buttons a.downloadlocation').attr("href", "data:text/json;charset=utf-8,#{encodeURIComponent(JSON.stringify(model))}")[0].click()
    toCharacters: ->
      @transitionToRoute 'chars'
    handleUpload: (result) ->
      @set 'model.image', "/dnd/api/image/#{result}"
    clickImage: ->
      Ember.$('.character .image input').click()

`export default CharController`
