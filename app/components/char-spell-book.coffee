`import Ember from 'ember'`

CharSpellBookComponent = Ember.Component.extend
  classNames: ["spells","spell-detail"]
  showDetails: false
  spellGroups: Ember.computed 'char.spellGroups', 'spells', ->
    spells = @get 'spells'
    spellgroups = @get 'char.spellGroup'
    
    Ember.ArrayProxy.create
      content: @get('char.spellGroups')
  spells: Ember.computed 'char.spellGroups.@each.spells', 'char.spellGroups.@each.title', ->
    map = {}
    groups = @get('char.spellGroups')
    groups.map (group) ->
      map[group.title.trim()] = Ember.ArrayProxy.create
        content: group.spells
    map
  actions:
    createSpellGroup: ->
      groups = @get 'spellGroups'
      groups.addObject
        title: "Spells"
        spells: []
      Ember.run.later ->
        target = Ember.$(".spell-group").last()
        $('html, body').animate
          scrollTop: Math.max(0, target.offset().top-100)
        , 1000

    addSpell: (group) ->
      @set 'showModal', true
      @set 'targetGroup', group
    closeDialog: ->
      @set 'showModal', false
    selectSpell: (spell) ->
      group = @get 'targetGroup'
      @set 'showModal', false
      spells = @get 'spells'
      spells[group.title.trim()].addObject spell
    createSpell: ->
      group = @get 'targetGroup'
      @set 'showModal', false
      spells = @get 'spells'      
      spells[group.title.trim()].addObject
        name: "New Spell"
        level: 0
        origin: "Evocation Cantrip"
        school: "Evocation"
        action: "1 action"
        range: "60 feet"
        components: "V, S"
        duration: "Instantaneous"
        description: "Something magical happens!"
    sortSpells: (group) ->
      spells = group.spells
      @propertyWillChange 'spellGroups'
      spells.sort (one, two) ->
        if one.name < two.name then -1 else 1
      @propertyDidChange 'spellGroups'
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
      s = spells[group.title.trim()]
      index = s.indexOf spell
      s.removeObject spell
      s.insertAt (Math.max(index-1,0)), spell
    spellDown: (group, spell) ->
      spells = @get 'spells'
      s = spells[group.title.trim()]
      index = s.indexOf spell
      s.removeObject spell
      s.insertAt (Math.min(index+1,s.get('length'))), spell
    spellRemove: (group, spell) ->
      spells = @get 'spells'
      s = spells[group.title.trim()]
      s.removeObject spell
    toggleSpellDetail: (spell) ->
      if not spell
        @toggleProperty 'showDetails'
      else
        Ember.set spell, 'details', not Ember.get(spell, 'details')
    toggleGroup: (group) ->
      Ember.set(group, 'open', !Ember.get(group, 'open'))

`export default CharSpellBookComponent`
