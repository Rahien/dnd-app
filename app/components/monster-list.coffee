`import Ember from 'ember'`

MonsterListComponent = Ember.Component.extend
  actions:
    removeMonster: (monster) ->
      @sendAction 'removeMonster', monster

`export default MonsterListComponent`
