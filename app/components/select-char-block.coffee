`import Ember from 'ember'`

SelectCharBlockComponent = Ember.Component.extend
  classNames: "select-char-block"
  blockDescriptions:
    attacks: { kind: "char-attacks", title: "Attacks" },
    profs: { kind: "char-profs", title: "Proficiencies" },
    inventory: { kind: "char-inventory", title: "Gear" },
    wealth: { kind: "specced", title: "Wealth", content: "wealth" },
    skills: { kind: "specced", title: "Skills", content: "skills" },
    traits: { kind: "specced", title: "Features and Traits", content: "traits" },
    feats: { kind: "specced", title: "Feats", content: "feats" },
    spells: { kind: "specced", title: "Spells", content: "spells" },
    description: { kind: "specced", title: "Short Description", content: "description" }
  blockTypes: Ember.computed "blockDescriptions", ->
    Object.keys(@get('blockDescriptions')).concat("custom")
  showExtra: Ember.computed.equal "blockType", "custom"
  canConfirm: Ember.computed "blockType", "title", "illegalData", ->
    @get('blockType') != "custom" or (@get('title') and not @get('illegalData'))
  illegalData: Ember.computed "data", ->
    illegal = [ "attacks", "profs", "inventory", "wealth", "skills", "traits", "feats", "spells", "spells", "description", "name", "race", "class", "level", "profBonus", "image", "spellGroups", "words" ]
    data = @get 'data'
    illegal.contains(data) or not data or data.indexOf(" ") >= 0 or data.indexOf(".") >= 0
  dataClass: Ember.computed "illegalData", ->
    if @get 'illegalData'
      "invalid"
    else
      "valid"
  actions:
    confirm: ->
      if not @get 'canConfirm'
        return
      block = Ember.merge({}, ( @get("blockDescriptions.#{@get('blockType')}") or { kind: "specced", title: @get('title'), content: @get('data') } ))
      @sendAction "confirmBlock", block
    cancel: ->
      @sendAction "confirmBlock", undefined
`export default SelectCharBlockComponent`
