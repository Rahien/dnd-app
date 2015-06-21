`import Ember from 'ember'`
`import EmberUploader from 'ember-uploader'`

FileUpload = EmberUploader.FileField.extend
  multiple: false,
  url: '',
  filesDidChange: Ember.observer 'files', ->
    uploadUrl = this.get 'url'
    files = this.get 'files'

    uploader = EmberUploader.Uploader.create
      url: uploadUrl

    if !Ember.isEmpty files
      uploader.upload(files[0]).then (result) =>
        @sendAction "didUpload", result

`export default FileUpload`
