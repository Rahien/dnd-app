class MyServer
  get '/dnd/api/allchars' do
    protected!
    admin!
    getAllCharacters().to_json
  end

  get '/dnd/api/char/:id' do
    protected!
    id = params[:id]
    if not canAccessChar(id)
      noAccess
    end
    getCharacter(id).to_json
  end

  put '/dnd/api/char/:id' do
    protected!
    id = params[:id]
    if not canAccessChar(id)
      noAccess
    end

    data = JSON.parse request.body.read
    begin
      saveCharacter(id,data)
    rescue => e
      halt 500, "Could not save character: #{e}"
    end
    ok
  end

  delete '/dnd/api/char/:id' do
    protected!
    id = params[:id]
    if not canAccessChar(id)
      noAccess
    end

    begin
      result = deleteCharacter(id)
      ok
    rescue => e
      halt 500, "Could not delete character: #{e}\n"
    end
  end

  post '/dnd/api/chars' do
    protected!
    data = JSON.parse request.body.read
    if not data["_id"].nil?
      halt 400, "Don't include _id when posting!\n"
    end
    begin
      character = createCharacter(data)
      id = character["_id"]
      addCharToUser(id)
      { id: id.to_str }.to_json
    rescue => e
      halt 500, "could not save character: #{e}\n"
    end
  end

  get '/dnd/api/chars' do
    protected!
    getCharacters().to_json
  end

  def getAllCharacters
    chars = MONGOC[CHARS].find().projection( { name: 1, class: 1, race: 1, level: 1 } )
    list = []
    chars.each do |item|
      item["_id"] = item["_id"].to_str
      list.push item
    end
    list
  end

  def getCharacters
    user = @auth.userid
    userResp = MONGOC[USERS].find( _id: user ).first()
    list = []

    if not userResp["admin"].nil? and userResp["admin"]
      list = getAllCharacters()
    else
      list = getUserChars(userResp)
    end
    list
  end

  def getUserChars(user)
    chars = []
    if not user["chars"].nil? and user["chars"].length > 0
      ids = user["chars"].map do |id|
        BSON::ObjectId(id)
      end
      chars = MONGOC[CHARS].find( { _id: { "$in" => ids } } )
                           .projection( { name: 1, class: 1, race: 1, level: 1 } )


      if chars.count != user["chars"].length
        userChars = []
        chars.each do |char|
          userChars.push char["_id"].to_str
        end
        user["chars"] = userChars
        updateUser(user)
      end
    end
    result = []
    chars.each do |char|
      char["_id"] = char["_id"].to_str
      result.push(char)
    end
    result
  end

  def addCharToUser (id)
    user = @auth.userid

    userDesc = MONGOC[USERS].find( _id: user ).first()
    if userDesc['chars'].nil?
      userDesc['chars'] = []
    end
    userDesc['chars'].push id

    MONGOC[USERS].find_one_and_update(
      { _id: user },
      { '$set' => { chars: userDesc['chars'] } },
      return_document: :after
    )
  end

  def getCharacter (id)
    result = MONGOC[CHARS].find({_id: BSON::ObjectId(id) })
    if result.count == 1
      result = result.first
      result["_id"] = result["_id"].to_str
      result
    else
      nil
    end
  end

  def saveCharacter (id, body)
    mongo_id = BSON::ObjectId(id)
    body['_id']= mongo_id
    MONGOC[CHARS].find_one_and_replace(
      { _id: mongo_id },
      { '$set' => body },
      return_document: :after
    )
  end

  def deleteCharacter (name)
    try do
      MONGOC[CHARS].delete_one(_id: BSON::ObjectId(name) )
    end
  end

  def createCharacter (body)
    result = MONGOC[CHARS].insert_one(body)
    body['_id'] = result.inserted_id.to_str
    body
  end

end
