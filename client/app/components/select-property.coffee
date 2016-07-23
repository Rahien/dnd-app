`import Ember from 'ember'`

SelectPropertyComponent = Ember.Component.extend
  init: ->
    @_super(arguments...)
    @set 'propType', @get('propertyList')?[0]?.id
  classNames: "select-char-block"
  propertyList: Ember.computed "properties", ->
    props = @get('properties')
    list = Object.keys(props).map (key) ->
      props[key]
    custom = { name: "custom", id: "custom" }
    list.sort firstBy("name")
    list.push(custom)
    list
  showExtra: Ember.computed.equal "propType", "custom"
  canConfirm: Ember.computed "propType", "title", "illegalData", ->
    @get('propType') != "custom" or (@get('title') and not @get('illegalData'))
  illegalData: Ember.computed "data", ->
    data = @get 'data'
    if not data or data.indexOf(" ") >= 0
      return true
    try
      Ember.get Ember.Object.create({}), @get('data')
      false
    catch
      true
  dataClass: Ember.computed "illegalData", ->
    if @get 'illegalData'
      "invalid"
    else
      "valid"
  actions:
    confirm: ->
      if not @get 'canConfirm'
        return
      id = @get 'propType'
      value = Ember.merge {}, @get('properties')[id]
      if id == "custom"
        value = { name: @get('title'), value: @get('data') }
      @sendAction "addProperty", value
    cancel: ->
      @sendAction "addProperty", undefined


`export default SelectPropertyComponent`
