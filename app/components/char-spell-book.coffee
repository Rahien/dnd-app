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
        title: "Ray of Frost"
        level: 1
        origin: "Evocation Cantrip"
        school: "Evocation"
        action: "1 action"
        range: "60 feet"
        components: "V, S"
        duration: "Instantanious"
        description: "A frigid beam of blue-white light streaks toward a creature within range. Make a ranged spell attack against the target. On a hit, it takes 1d8 cold damage, and its speed is reduced by 10 feet until the start of your next turn. The spell's damage increases by 1d8 when you reach 5th level (2d8), 11th level (3d8), and 17th level (4d8)."
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
