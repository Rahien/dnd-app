`import Ember from 'ember'`
`import SaveLoadModelMixin from '../../../mixins/save-load-model'`
`import { module, test } from 'qunit'`

module 'SaveLoadModelMixin'

# Replace this with your real tests.
test 'it works', (assert) ->
  SaveLoadModelObject = Ember.Object.extend SaveLoadModelMixin
  subject = SaveLoadModelObject.create()
  assert.ok subject
