class MyServer
  get '/dnd/api/monster/:id' do
    protected!
    id = params[:id]

    getMonster(id).to_json
  end

  put '/dnd/api/monster/:id' do
    protected!
    id = params[:id]
    if not canAccessMonster(id)
      noAccess
    end

    data = JSON.parse request.body.read
    begin
      saveMonster(id,data)
    rescue => e
      halt 500, "Could not save monster: #{e}"
    end
    ok
  end

  delete '/dnd/api/monster/:id' do
    protected!
    id = params[:id]
    if not canAccessMonster(id)
      noAccess
    end

    begin
      result = deleteMonster(id)
      ok
    rescue => e
      halt 500, "Could not delete monster: #{e}\n"
    end
  end

  post '/dnd/api/monsters' do
    protected!
    data = JSON.parse request.body.read
    if not data["_id"].nil?
      halt 400, "Don't include _id when posting!\n"
    end
    begin
      monster = createMonster(data)

      { id: monster['_id'].to_str }.to_json
    rescue => e
      halt 500, "could not save monster: #{e}\n"
    end
  end

  get '/dnd/api/monsters' do
    protected!
    getMonsters(params).to_json
  end

  def cleanMonster(monster, noOwners = false)
    monster["_id"] = monster["_id"].to_str
    if noOwners
      monster.delete "owners"
    end
    monster
  end

  def getMonsters (params)
    user = @auth.userid

    finder = {}
    unless params[:search].nil?
      finder['$text'] = { '$search' => params[:search] }
    end
    [:type, :cr, :align, :size].map do |prop|
      unless params[prop].nil?
        finder[prop.to_s] = params[prop]
      end
    end

    monsters = MONGOC[MONSTERS].find( finder )
                         .projection( { name: 1, cr: 1, size: 1, type: 1, align: 1, owner: 1 } )

    addItemOwners(monsters)
    result = []
    monsters.each do |monster|
      result.push(cleanMonster(monster))
    end
    result
  end

  def getMonster (id)
    result = MONGOC[MONSTERS].find({_id: BSON::ObjectId(id) })
    if result.count == 1
      result = cleanMonster(result.first)
      addItemOwners([result])
      result
    else
      nil
    end
  end

  def saveMonster (id, body)
    mongo_id = BSON::ObjectId(id)
    body.delete 'owner'
    body['_id']= mongo_id
    MONGOC[MONSTERS].find_one_and_replace(
      { _id: mongo_id },
      { '$set' => body },
      return_document: :after
    )
  end

  def deleteMonster (id)
    try do
      MONGOC[MONSTERS].delete_one(_id: BSON::ObjectId(id) )
    end
  end

  def createMonster (body)
    body['owners'] = [ @auth.userid ]
    result = MONGOC[MONSTERS].insert_one(body)
    body['_id'] = result.inserted_id.to_str
    body
  end

end
