`import Ember from 'ember'`

CharSpellBookComponent = Ember.Component.extend
  classNames: ["spells","spell-detail"]
  spellGroups: Ember.computed 'char.spellGroups', 'spells', ->
    spells = @get 'spells'
    spellgroups = @get 'char.spellGroup'
    
    Ember.ArrayProxy.create
      content: @get('char.spellGroups')
  spells: Ember.computed 'char.spellGroups.@each.spells.@each', ->
    map = {}
    groups = @get('char.spellGroups')
    groups.map (group) ->
      map[group.title] = Ember.ArrayProxy.create
        content: group.spells
    map

`export default CharSpellBookComponent`
