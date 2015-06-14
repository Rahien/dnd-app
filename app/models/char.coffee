`import Ember from 'ember'`

Char = Ember.Object.extend
  carry: Ember.computed "abilities.str", ->
    str = @get 'abilities.str'
    str*15
  pushOrDrag: Ember.computed "abilities.str", ->
    str = @get 'abilities.str'
    str*30

`export default Char`
