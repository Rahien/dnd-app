`import Ember from 'ember'`
`import config from './config/environment'`

Router = Ember.Router.extend
  location: config.locationType

Router.map ->
  @route 'login', path: "/dnd/app"
  @route 'char', path: "/dnd/app/char/:id"
  @route 'chars', path: "/dnd/app/chars"
  @route 'register', path: "/dnd/app/register"
  @route 'players', path: "/dnd/app/players"

`export default Router`
