`import Ember from 'ember'`

MonsterListComponent = Ember.Component.extend
  actions:
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
