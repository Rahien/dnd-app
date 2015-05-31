`import Ember from 'ember'`

CharTraitsComponent = Ember.Component.extend
  classNames: ["traits"]
  init: ->
    @_super(arguments...)

    @set 'traits', "Draconic Ancestry\n=================\nDamage resistance fire\nBreath Weapon\n===================\nSaving throw DC 8 + Con modifier + prof. bonus. 2d6 damage on fail and half damage on success. Increase at 6th, 11th, 16th level. Recharges after short rest.\nBackground - Sage, wizard's apprentice\n===================\nIf you don't know a piece of information, you will (most likely) know how to obtain such lore.\nSpellcasting focus\n===================\nYou can use an arcane focus as a spellcasting focus\nSorcery points\n===================\nmax 1 per level, create spell slot up to level 5, cost increases by 1 per level, two at level 3. You can also expend a spell slot and gain sorcery points up to that level.\nCareful spell\n===================\nProtect up to Cha modifier creatures from your own spell's effect. Costs one SP.\nBronze Dragon Ancestor\n===================\nDamage type: lightning. Additionally, prof. bonus is doubled when using Cha. interacting with dragons.\nDraconic Resilience\n===================\nOne extra HP per sorcerer level. AC = 13 + Dex when not wearing armor."

`export default CharTraitsComponent`
