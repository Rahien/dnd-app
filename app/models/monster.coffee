`import DS from 'ember-data'`

Monster = Ember.Object.extend {
  
}

Monster.getDefault = ->
  Monster.create
    name: "A rat in the basement"
    attacks: []
    stats:
      str: 16
      dex: 16
      con: 14
      int: 8
      wis: 12
      cha: 4
    size: "Small"
    type: "beast"
    alignment: "chaotic neutral"
    ac: 12
    hp: "8 (1d8 + 3)"
    speed: '30 ft, burrow 10 ft'
    challenge: '1/8'
    stats: [
      { label: "skills", value: "perception, stealth +1" },
      { label: "senses", value: "darkvision, 60 ft." },
      { label: "languages", value: "-" }
    ]
    traits: ""
    actions: ""
    

`export default Monster`
