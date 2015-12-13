`import Ember from 'ember'`

SelectSpellComponent = Ember.Component.extend
  classNames: ["spell-select"]
  init: ->
    @_super(arguments...)
    @set 'data', []
    @set 'searchString', ""
    @set 'useClass', true
  didInsertElement: ->
    @_super(arguments...)
    Ember.run.later this, (->
      @$().find(".search input").focus()), 500
  # timestamp of last fetch
  searchWait: 3000
  fetchResults: Ember.observer 'searchString', 'useClass', ->
    @set 'shouldFetch', true
    # notify interests
    @get 'useClass'
    search = @get 'searchString'

    if search.length > 2
      Ember.run.throttle this, @doFetch, 2000, false
  doFetch: ->
    url = "/dnd/api/spells"
    params =
      search: @get 'searchString'
    if @get 'useClass'
      params.class = @get 'char.class'

    Ember.$.ajax url,
      data: params
      success: (result, status, xhr) =>
        @set 'data', JSON.parse(result)
      error: () =>
        @set 'data', []
  results: Ember.computed.alias 'data'
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
