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
    addSpell: (group) ->
      @set 'showModal', true
      @set 'targetGroup', group
    closeDialog: ->
      @set 'showModal', false
    selectSpell: (spell) ->
      group = @get 'targetGroup'
      @set 'showModal', false
      spells = @get 'spells'
      spells[group.title].addObject spell
    createSpell: ->
      group = @get 'targetGroup'
      @set 'showModal', false
      spells = @get 'spells'      
      spells[group.title].addObject
        name: "New Spell"
        level: 0
        origin: "Evocation Cantrip"
        school: "Evocation"
        action: "1 action"
        range: "60 feet"
        components: "V, S"
        duration: "Instantanious"
        description: "Something magical happens!"
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
    groupRemove: (group) ->
      groups = @get 'spellGroups'
      groups.removeObject group
    spellUp: (group, spell) ->
      spells = @get 'spells'
      s = spells[group.title]
      index = s.indexOf spell
      s.removeObject spell
      s.insertAt (Math.max(index-1,0)), spell
    spellDown: (group, spell) ->
      spells = @get 'spells'
      s = spells[group.title]
      index = s.indexOf spell
      s.removeObject spell
      s.insertAt (Math.min(index+1,s.get('length'))), spell
    spellRemove: (group, spell) ->
      spells = @get 'spells'
      s = spells[group.title]
      s.removeObject spell

`export default CharSpellBookComponent`
