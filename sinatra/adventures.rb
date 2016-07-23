class MyServer
  post '/dnd/api/adventures' do
    protected!
    data = JSON.parse request.body.read
    if not data["_id"].nil?
      halt 400, "Don't include _id when posting!\n"
    end
    begin
      adventure = createAdventure(data)
      id = adventure["_id"].to_str
      { id: id }.to_json
    rescue => e
      halt 500, "could not save adventure: #{e}\n"
    end
  end

  get '/dnd/api/adventures' do
    protected!
    getAdventures().to_json
  end

  get '/dnd/api/adventure/:id' do
    protected!
    adventure = fetchAdventure(params[:id])
    if ownsAdventure?(adventure)
      adventure['edit'] = true
    else
      adventure.delete "dmNotes"
      adventure.delete "chars"
      adventure.delete "monsters"
      adventure['edit'] = false
    end
    addItemOwners([adventure])
    adventure["_id"] = adventure["_id"].to_str
    adventure.to_json
  end

  put '/dnd/api/adventure/:id' do
    protected!
    adventure = fetchAdventure(params[:id])
    unless ownsAdventure? adventure
      halt 401, "You don't own this adventure"
    end
    data = JSON.parse request.body.read
    data.delete("_id")
    MONGOC[ADVENTURES].update_one( { _id: adventure["_id"] } , { "$set" => data } )
    ok
  end

  delete '/dnd/api/adventure/:id' do
    protected!
    adventure = fetchAdventure(params[:id])
    unless ownsAdventure? adventure
      halt 401, "You don't own this adventure"
    end
    MONGOC[ADVENTURES].delete_one( _id: adventure["_id"] )
    ok
  end

  def fetchAdventure (id)
    found = MONGOC[ADVENTURES].find(_id: BSON::ObjectId(params['id']))
    if not found.count == 1
      halt 404, "Adventure not found\n"
    end

    adventure = found.first()
  end

  def getAdventures
    adventures = nil
    if isAdmin
      adventures = getAllAdventures()
    else
      user = @auth.userid
      adventures = getUserAdventures(user)
    end

    addItemOwners(adventures)
    adventures
  end

  def getAllAdventures
    advs = []
    MONGOC[ADVENTURES].find().projection( name: 1, date: 1, owner: 1 ).each do |adv|
      adv["_id"] = adv["_id"].to_str
      advs.push adv
    end
    advs
  end

  def getUserAdventures (userId)
    adventures = []
    userResp = MONGOC[USERS].find( _id: userId ).first()
    chars = userResp["chars"]
    if chars.nil?
      return adventures
    end

    result = MONGOC[ADVENTURES].find( { chars: { "$elemMatch" => { "_id" => { "$in" => chars } } } } ).projection( name: 1, date: 1, owner: 1 )
    result.each do |adv|
      adv["_id"] = adv["_id"].to_str
      adventures.push adv
    end
    adventures
  end

  def createAdventure (body)
    body["owner"] = @auth.userid

    result = MONGOC[ADVENTURES].insert_one(body)
    body['_id'] = result.inserted_id.to_str
    body
  end

end
