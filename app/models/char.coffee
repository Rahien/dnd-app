`import Ember from 'ember'`

Char = Ember.Object.extend
  carry: Ember.computed "abilities.str", ->
    str = @get 'abilities.str'
    str*15
  pushOrDrag: Ember.computed "abilities.str", ->
    str = @get 'abilities.str'
    str*30
  serialize: ->
    simplify = JSON.stringify(this)
    JSON.parse(simplify)

Char.getDefault = ->
  Char.create 
    name: "Unnamed Hero"
    class: "Sorcerer"
    race: "Red Dragonborn"
    level: 3
    image: "/assets/images/sorceress.png"
    description: "Not much is known about this character yet, it has yet to write its own destiny."
    stats: [
      { label: "height", value: "6'4\"" },
      { label: "weight", value: "260 lb." },
      { label: "size", value: "Medium" },
      { label: "speed", value: "30 ft." },
      { label: "vision", value: "normal" },
      { label: "deity", value: "Magic" },
      { label: "languages", value: "Common, Draconic, Demonic, Dwarven" },
      { label: "alignment", value: "Chaotic Neutral" }
    ]
    notes: ""
    hp:
      current: ""
      total: ""
    hd:
      current: ""
      total: "3d6"
    ac:
      armor: "14"
      noArmor: "13"
    abilities:
      str: 10
      dex: 13
      con: 14
      int: 10
      wis: 12
      cha: 16
    initiative: 3
    perception: 1
    attacks: [
      {
        name: "Dagger"
        attack: "Dex"
        damage: "1d4"
        def: "AC"
        range: ""
        type: "piercing"
      },
      {
        name: "Dagger (thrown)"
        attack: "Dex"
        damage: "1d4"
        def: "AC"
        range: "20/60"
        type: "piercing"
      },
      {
        name: "Quarterstaff"
        attack: "Dex"
        damage: "1d6/1d8"
        def: "AC"
        range: ""
        type: "bludg."
      },
      {
        name: "Ray of frost"
        attack: "Spell"
        damage: "1d8"
        def: "DC"
        range: "60"
        type: "cold"
      }
    ]
    profs:
      saves: "Constitution, Charisma"
      armor: "None"
      weapons: "Daggers, darts, slings, quarterstaffs, light crossbows"
      tools: "None"
      skills: "Arcana (Int), Intimidation (Cha), Persuasion (Cha), History (Int)"
    traits: "Draconic Ancestry\n=================\nDamage resistance fire\nBreath Weapon\n===================\nSaving throw DC 8 + Con modifier + prof. bonus. 2d6 damage on fail and half damage on success. Increase at 6th, 11th, 16th level. Recharges after short rest.\nBackground - Sage, wizard's apprentice\n===================\nIf you don't know a piece of information, you will (most likely) know how to obtain such lore.\nSpellcasting focus\n===================\nYou can use an arcane focus as a spellcasting focus\nSorcery points\n===================\nmax 1 per level, create spell slot up to level 5, cost increases by 1 per level, two at level 3. You can also expend a spell slot and gain sorcery points up to that level.\nCareful spell\n===================\nProtect up to Cha modifier creatures from your own spell's effect. Costs one SP.\nBronze Dragon Ancestor\n===================\nDamage type: lightning. Additionally, prof. bonus is doubled when using Cha. interacting with dragons.\nDraconic Resilience\n===================\nOne extra HP per sorcerer level. AC = 13 + Dex when not wearing armor."
    gear: [
      {
        name: "Quarterstaff"
        price: 2
        weight: 4
        notes: "versatile"
      },
      {
        name: "Common Clothing"
        price: 1
        weight: 3
        notes: ""
      }
    ]
    wealth: "70 gp."
    feats: ""
    spells: "Does not need to prepare spells in advance, can swap spells on level up. Spell slots restored on long rest.\n\nSpell DC\n==========\n8 + prof. bonus + Cha mod.\nSpell attack modifier\n========\nprof. bonus + Cha mod.\nCantrips known\n====\n4\nSpells known\n====\n4\nSpell Slots\n======\n| level |     1 | 2 |\n|--|--|--|\n| slots |     4 | 2 |\n"
    spellGroups: [
      {
        title: "Cantrips"
        spells: [
          {
            name: "Ray of Frost"
            level: 1
            origin: "Evocation Cantrip"
            school: "Evocation"
            action: "1 action"
            range: "60 feet"
            components: "V, S"
            duration: "Instantanious"
            description: "A frigid beam of blue-white light streaks toward a creature within range. Make a ranged spell attack against the target. On a hit, it takes 1d8 cold damage, and its speed is reduced by 10 feet until the start of your next turn. The spell's damage increases by 1d8 when you reach 5th level (2d8), 11th level (3d8), and 17th level (4d8)."
          }
        ]
      }
   ]


`export default Char`
