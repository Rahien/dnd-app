class MyServer
  post '/dnd/api/image' do
    file = params[:file][:tempfile]
    type = params[:file][:type]
    id = createAttachment(file,type)
    { id: id }.to_json
  end

  get '/dnd/api/image/:name' do
    name = params[:name]
    getAttachment(name)
  end

  def createAttachment (file,type)
    grid_file = Mongo::Grid::File.new(file.read, :filename => File.basename(file.path))
    fileId = MONGOC.database.fs.insert_one(grid_file)
    fileId.to_str
  end

  def getAttachment (name)
    result = MONGOC.database.fs.find_one(:_id => BSON::ObjectId(name))
    result.data
  end

end
