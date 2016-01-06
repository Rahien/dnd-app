`import Ember from 'ember'`
`import Char from './char'`

Adventure = Ember.Object.extend
  serialize: ->
    simplify = JSON.parse(JSON.stringify(this))
    simplify.owner = simplify.owner._id
    simplify
  init: ->
    @_super(arguments...)
    chars = @get 'chars'
    newChars = chars.map (char) ->
      Char.create(char)
    chars.splice.apply(chars,[0,Number.MAX_VALUE].concat(newChars))

Adventure.getDefault = ->
  Adventure.create 
    name: "Once more unto the breach"
    date: Date.now()
    chars: []
    dmNotes: ""

`export default Adventure`
