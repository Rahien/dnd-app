`import Ember from 'ember'`

MonsterListComponent = Ember.Component.extend
  actions:
    saveMonster: (monster) ->
      url = "/dnd/api/monsters"
      type = "POST"
      monsterId = @get 'monster._id'
      serialized = monster.serialize()

      if monsterId
        url = "/dnd/api/monster/#{@get('monster._id')}"
        type = "PUT"

      Ember.$.ajax url,
        type: type
        contentType: "application/json; charset=utf-8"
        data: JSON.stringify(serialized)
        success: =>
          @sendMessage 'goodstuff', "Monster saved"
        error: (error) =>
          @sendMessage 'error', "Could not save monster: #{error.responseText}"

    addTrait: (monster) ->
      monster.set 'traits', "New trait\n=====\nTrait description"
    addAction: (monster) ->
      monster.set 'actions', "New action\n=====\nAction description"
    addLegendary: (monster) ->
      monster.set 'legendary', "New legendary action\n=====\nAction description"
    addReaction: (monster) ->
      monster.set 'reactions', "New reaction\n=====\nReaction description"
    removeMonster: (monster) ->
      @sendAction 'removeMonster', monster

`export default MonsterListComponent`
