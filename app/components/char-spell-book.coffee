`import Ember from 'ember'`

CharSpellBookComponent = Ember.Component.extend
  classNames: ["spells","spell-detail"]
  spellGroups: Ember.computed 'char.spellGroups', 'spells', ->
    spells = @get 'spells'
    spellgroups = @get 'char.spellGroup'
    
    Ember.ArrayProxy.create
      content: @get('char.spellGroups')
  spells: Ember.computed 'char.spellGroups.@each.spells', ->
    map = {}
    groups = @get('char.spellGroups')
    groups.map (group) ->
      map[group.title] = Ember.ArrayProxy.create
        content: group.spells
    map
  actions:
    createSpellGroup: ->
      groups = @get 'spellGroups'
      groups.addObject
        title: "Spells"
        spells: []
    createSpell: (group) ->
      spells = @get 'spells'      
      spells[group.title].addObject
        title: "spell"
        level: 1
        origin: "wizard 1"
        school: "evocation"
        action: "action"
        range: "self"
        components: "nothing"
        duration: "1 minute/level"
        description: "foobar"
    groupUp: (group) ->
      groups = @get 'spellGroups'
      index = groups.indexOf group
      groups.removeObject group
      groups.insertAt (Math.max(index-1,0)), group
    groupDown: (group) ->
      groups = @get 'spellGroups'
      index = groups.indexOf group
      groups.removeObject group
      groups.insertAt (Math.min(index+1,groups.get('length'))), group

`export default CharSpellBookComponent`
