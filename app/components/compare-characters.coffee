`import Ember from 'ember'`

CompareCharactersComponent = Ember.Component.extend
  properties: [
    { value: "class", name: "class"},
    { value: "race", name: "race"},
    { value: "level", name: "level" },
    { value: "abilities.str", name: "strength" }
    { value: "abilities.dex", name: "dexterity" }
    { value: "abilities.con", name: "constitution" }
    { value: "abilities.int", name: "intelligence" }
    { value: "abilities.wis", name: "wisdom" }
    { value: "abilities.cha", name: "charisma" }
    { value: "initiative", name: "initiative" }
    { value: "hp.current", name: "HP" }
    { value: "hp.total", name: "HP total" }
    { value: "hd.total", name: "HD" }
    { value: "ac.armor", name: "AC" }
    { value: "ac.noArmor", name: "AC no armor" }
  ]
  actions:
    unlinkCharacter: (char) ->
      @sendAction "unlinkCharacter", char

`export default CompareCharactersComponent`
