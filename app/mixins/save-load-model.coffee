`import Ember from 'ember'`

SaveLoadModelMixin = Ember.Mixin.create
  actions:
    download: ->
      model = @get 'model'
      Ember.$('a.downloadlocation').attr("href", "data:text/json;charset=utf-8,#{encodeURIComponent(JSON.stringify(model.serialize()))}")[0].click()
    doUpload: ->
      input = Ember.$('input.uploadInput')[0]
      file = input.files[0]
      onError = =>
        @sendMessage 'error', "Sorry, could not read the file"
      if file
        reader = new FileReader()
        reader.readAsText(file, "UTF-8")
        reader.onload = (evt) =>
          try
            object = JSON.parse(evt.target.result)
            model = @get 'model'
            id = model._id
            rev = model._rev
            object._id = id
            object._rev = rev
            @set 'model', @modelFromObject(object)

            @doSave()
          catch e
            onError()
        reader.onerror = onError
        try
          input.value = ''
          if input.value
            input.type = "text"
            input.type = "file"
        catch e
          "tried our best to clear the input"


`export default SaveLoadModelMixin`
