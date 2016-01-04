`import Ember from 'ember'`

CompareCharactersComponent = Ember.Component.extend
  properties: ["class", "level", "attrs.strength"]
  actions:
    unlinkCharacter: (char) ->
      @sendAction "unlinkCharacter", char

`export default CompareCharactersComponent`
