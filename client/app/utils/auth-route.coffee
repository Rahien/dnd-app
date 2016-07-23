`import Ember from 'ember'`
`import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';`

AuthRoute = Ember.Route.extend AuthenticatedRouteMixin,
  session: Ember.inject.service('session')

`export default AuthRoute`
