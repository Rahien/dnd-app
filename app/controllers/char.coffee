`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`
`import Char from '../models/char'`

CharController = Ember.Controller.extend SendMessage,
  init: ->
    @_super(arguments...)
  charBlocks: Ember.Object.create
    left: Ember.ArrayProxy.create content: [
      { kind: "char-attacks" },
      { kind: "char-profs" },
      { kind: "char-inventory" },
      { kind: "specced", title: "Wealth", content: "wealth" }
    ]
    right: Ember.ArrayProxy.create content: [
      { kind: "specced", title: "Skills", content: "skills" },
      { kind: "specced", title: "Features and Traits", content: "traits" },
      { kind: "specced", title: "Feats", content: "feats" },
      { kind: "specced", title: "Spells", content: "spells" },
      { kind: "specced", title: "Spellbook", content: "spellbook" },
      { kind: "specced", title: "Short Description", content: "description" }
    ]
  profBonus: Ember.computed "model.level", ->
    level = @get 'model.level'
    Math.floor(level/4)+2
  filename: Ember.computed "model.name", ->
    name = @get 'model.name'
    name.replace(/[^a-z0-9]/gi, '_').toLowerCase();
  doSave: ->
    model = @get 'model'
    Ember.$.ajax "/dnd/api/char/#{model._id}",
      method: "PUT"
      data: JSON.stringify(model.serialize())
      contentType: "application/json; charset=utf-8"
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
    moveBlockUp: (block) ->
      blocks = @get 'charBlocks'
      index = blocks.get('left').indexOf(block)
      
      if index < 0
        index = blocks.get('right').indexOf(block)
        blocks = blocks.get('right')
      else
        blocks = blocks.get('left')

      if index == 0
        return
      blocks.removeAt(index)
      blocks.insertAt(index-1,block)
      
    moveBlockDown: (block) ->
      blocks = @get 'charBlocks'
      index = blocks.get('left').indexOf(block)
      
      if index < 0
        index = blocks.get('right').indexOf(block)
        blocks = blocks.get('right')
      else
        blocks = blocks.get('left')

      if index == blocks.get('length')-1
        return
      blocks.removeAt(index)
      blocks.insertAt(index+1,block)
      
    removeBlock: (block) ->
      @get('charBlocks.left').removeObject(block)
      @get('charBlocks.right').removeObject(block)

    addNewBlockBelow: (block) ->
      @set 'targetBlock', block
      @set 'selectNewBlock', true

    confirmNewBlock: (block) ->
      blocks = @get 'charBlocks'
      target = @get 'targetBlock'
      @set 'selectNewBlock', false

      if not target or not block
        return
      index = blocks.get('left').indexOf(target)
      
      if index < 0
        index = blocks.get('right').indexOf(target)
        blocks = blocks.get('right')
      else
        blocks = blocks.get('left')

      blocks.insertAt(index+1,block)
      

`export default CharController`
