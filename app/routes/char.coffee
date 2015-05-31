`import Ember from 'ember'`
`import Char from '../models/char'`

CharRoute = Ember.Route.extend
  model: ->
    Char.create()

`export default CharRoute`
