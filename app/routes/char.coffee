`import Ember from 'ember'`
`import Char from '../models/char'`

CharRoute = Ember.Route.extend
  model: ->
    Char.create
      name: "Thavann Nirissh"
      class: "Sorcerer"
      race: "Red Dragonborn"
      level: 3
      image: "/assets/images/sorceress.png"
      description: "As a dragonborn, you have dedicated your life to honor and the pursuit of excellence. You are driven, noble, but in contrast to regular dragonborn, you can have trouble containing the wilder parts of your dragon heritage. As a Sorceress, you realized that precisely this wilder power grants you strength, which you will use to achieve your goals."
      keywords: "massive magic damage, dragon-like, low armor, rage"
      stats: [
        { label: "heigh", value: "6'4\"" },
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
      perception: 11
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
      skills: "Arcana (Int), Intimidation (Cha), Persuasion (Cha), History (Int)"
      feats: ""
      spells: "Spell DC\n==========\n8 + prof. bonus + Cha mod.\nSpell attack Modifier\n========\nprof. bonus + Cha mod.\nCantrips known\n====\n4\nSpells known\n====\n4\nSpell Slots\n======\n| level |     1 | 2 |\n|--|--|--|\n| slots |     4 | 2 |\n"
      spellbook: "Does not need to prepare spells in advance, can swap spells on level up. Spell slots restored on long rest.\nCantrips\n====\nLight, Message, Blade ward, Ray of frost\nLevel 1\n====\nBurning hands, Thunderweave"
      spellGroups: [
        {
          title: "cantrips"
          spells: [
            {
              title: "foobar"
              level: 1
              origin: "baz"
              school: "bang"
              action: "bing"
              range: "touch"
              components: "boz"
              duration: "bonzo"
              description: "wtf"
            }
          ]
        }
      ]
`export default CharRoute`
