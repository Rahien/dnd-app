`import Ember from 'ember'`

Adventure = Ember.Object.extend
  serialize: ->
    simplify = JSON.stringify(this)
    JSON.parse(simplify)

Adventure.getDefault = ->
  Adventure.create 
    name: "Once more unto the breach"
    date: Date.now()

`export default Adventure`
