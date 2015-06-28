`import Ember from 'ember'`

SelectSpellComponent = Ember.Component.extend
  classNames: ["spell-select"]
  init: ->
    @_super(arguments...)
    @set 'data', []
    @set 'searchString', ""
    @set 'useClass', true
    @fetchData()
  didInsertElement: ->
    @_super(arguments...)
    Ember.run.later this, (->
      @$().find(".search input").focus()), 500
  classObserver: Ember.observer 'useClass', ->
    @get 'useClass'
    @fetchData()
  fetchData: ->
    url = "/dnd/api/spells"
    c = @get 'char.class'
    if @get 'useClass'
      url += "/#{c}"
    Ember.$.ajax url,
      success: (result) =>
        @set 'data', JSON.parse(result)
      error: () =>
        @set 'data', []
  results: Ember.computed 'data', 'searchString', ->
    results = []
    data = @get 'data'
    search = @get('searchString').toLowerCase()
    if Ember.isEmpty search
      return results
      
    data?.map? (spell) ->
      if spell.name.toLowerCase().indexOf(search) >= 0
        results.push spell
    results.sort (one,two) ->
      if one.level == two.level
        if one.name <= two.name
          -1
        else
          1
      else
        one.level - two.level
    results
  actions:
    selectSpell: (spell) ->
      @sendAction "selectSpell", spell
    selectFirst: ->
      first = @get('results')[0]
      if first
        @sendAction "selectSpell", first
    newSpell: ->
      @sendAction "newSpell"
    closeDialog: ->
      @sendAction "closeDialog"

`export default SelectSpellComponent`
