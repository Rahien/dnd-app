# Takes two parameters: container and app
initialize = (container, app) ->
  app.inject('controller', 'user', 'service:user')
  app.inject('route', 'user', 'service:user')

UserInitializer =
  name: 'user'
  initialize: initialize

`export {initialize}`
`export default UserInitializer`
