`import Ember from 'ember'`
`import config from './config/environment'`

Router = Ember.Router.extend
  location: config.locationType

Router.map ->
  @route 'login', path: "/dnd/app"
  @route 'char', path: "/dnd/app/char/:id"
  @route 'chars', path: "/dnd/app/chars"
  @route 'adventures', path: "/dnd/app/adventures"
  @route 'adventure', path: "/dnd/app/adventure/:id"
  @route 'register', path: "/dnd/app/register"
  @route 'settings', path: "/dnd/app/settings"
  @route 'players', path: "/dnd/app/players"

  @route 'index', path: "*badPath"
  @route 'index', path: "/"

jQuery.expr[":"].Contains = jQuery.expr.createPseudo (arg) ->
  ( elem ) ->
    jQuery(elem).text().toUpperCase().indexOf(arg.toUpperCase()) >= 0


`export default Router`
