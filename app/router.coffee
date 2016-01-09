`import Ember from 'ember'`
`import config from './config/environment'`

Router = Ember.Router.extend
  location: config.locationType
  clearMenu: Ember.on 'didTransition', ->
    # TODO another reason to switch away from controllers to components
    applicationController = @container.lookup('controller:application')
    if applicationController
  	  applicationController.set 'showButtons', false

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

`export default Router`
