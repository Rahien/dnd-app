`import Ember from 'ember'`
`import AuthRoute from '../utils/auth-route'`
`import SendMessage from '../mixins/send-message'`

CharsRoute = AuthRoute.extend SendMessage,
  model: ->
    @store.findAll('character', reload: true)

`export default CharsRoute`
