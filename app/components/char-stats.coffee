`import Ember from 'ember'`

CharStatsComponent = Ember.Component.extend
  classNames: ["stats"]
  stats: Ember.computed "char.stats", ->
    Ember.ArrayProxy.create
      content: @get('char.stats')
  keywords: Ember.computed.alias "char.keywords"
  actions:
    deleteProp: (prop) ->
      @get('stats').removeObject(prop)
    createProp: ->
      @get('stats').addObject
        label: "property"
        value: "value"


`export default CharStatsComponent`
