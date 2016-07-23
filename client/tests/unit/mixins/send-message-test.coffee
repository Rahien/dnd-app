`import Ember from 'ember'`
`import SendMessageMixin from '../../../mixins/send-message'`
`import { module, test } from 'qunit'`

module 'SendMessageMixin'

# Replace this with your real tests.
test 'it works', (assert) ->
  SendMessageObject = Ember.Object.extend SendMessageMixin
  subject = SendMessageObject.create()
  assert.ok subject
