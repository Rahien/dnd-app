`import Ember from 'ember'`
`import SendMessage from '../mixins/send-message'`
`import SaveLoad from '../mixins/save-load-model'`
`import Char from '../models/char'`

CharController = Ember.Controller.extend SendMessage, SaveLoad,
  init: ->
    @_super(arguments...)
  showSpells: Ember.computed "charBlocks.left.[]", "charBlocks.right.[]", ->
    left = @get 'charBlocks.left'
    right = @get 'charBlocks.right'

    found = false
    left.toArray().concat(right.toArray()).map (block) ->
      if block.content == "spells"
        found = true
    found
  charBlocks: Ember.computed "model.charBlocks", ->
    current = @get 'model.charBlocks'
    if not current
      current =
        left: Ember.ArrayProxy.create content: [
          { kind: "char-attacks" },
          { kind: "char-profs" },
          { kind: "char-inventory" },
          { kind: "specced", title: "Wealth", content: "wealth" }
        ]
        right: Ember.ArrayProxy.create content: [
          { kind: "specced", title: "Features and Traits", content: "traits" },
          { kind: "specced", title: "Feats", content: "feats" },
          { kind: "specced", title: "Spells", content: "spells" },
          { kind: "specced", title: "Short Description", content: "description" }
        ]
       @set 'model.charBlocks', current
    else if not @get('model.charBlocks.left.content')
      @set 'model.charBlocks.left', Ember.ArrayProxy.create content: @get('model.charBlocks.left')
      @set 'model.charBlocks.right', Ember.ArrayProxy.create content: @get('model.charBlocks.right')
    current

  filename: Ember.computed "model.name", ->
    name = @get 'model.name'
    name.replace(/[^a-z0-9]/gi, '_').toLowerCase();
  doSave: ->
    model = @get 'model'
    serialized = model.serialize()
    serialized.charBlocks =
      left: @get('charBlocks.left.content')
      right: @get('charBlocks.right.content')
    Ember.$.ajax "/dnd/api/char/#{model._id}",
      method: "PUT"
      data: JSON.stringify(serialized)
      contentType: "application/json; charset=utf-8"
      success: =>
        @sendMessage 'goodstuff', 'Saved character'
      error: =>
        @sendMessage 'error', 'Could not save character!'
  modelFromObject: (object) ->
    Char.create object
  actions:
    save: ->
      @doSave()
    handleUpload: (result) ->
      @set 'model.image', "/dnd/api/image/#{result}"
    clickImage: ->
      Ember.$('.character .image input').click()
    moveBlockUp: (block) ->
      blocks = @get 'charBlocks'
      index = Ember.get(blocks,'left').indexOf(block)
      
      if index < 0
        index = Ember.get(blocks, 'right').indexOf(block)
        blocks = Ember.get(blocks, 'right')
      else
        blocks = Ember.get(blocks, 'left')

      if index == 0
        return
      blocks.removeAt(index)
      blocks.insertAt(index-1,block)
      
    moveBlockDown: (block) ->
      blocks = @get 'charBlocks'
      index = Ember.get(blocks,'left').indexOf(block)
      
      if index < 0
        index = Ember.get(blocks,'right').indexOf(block)
        blocks = Ember.get(blocks,'right')
      else
        blocks = Ember.get(blocks,'left')

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
      index = Ember.get(blocks,'left').indexOf(target)
      
      if index < 0
        index = Ember.get(blocks,'right').indexOf(target)
        blocks = Ember.get(blocks,'right')
      else
        blocks = Ember.get(blocks,'left')

      blocks.insertAt(index+1,block)
      

`export default CharController`
