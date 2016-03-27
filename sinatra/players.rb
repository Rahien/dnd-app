class MyServer
  post '/token' do
    if params[:grant_type] == "password"
      user = params[:username]
      pwd = params[:password]

      id = pwdOk(user, pwd)
      if id
        token, refresh = token! id
        {
          "access_token" => token,
          "token_type" => "bearer",
          "refresh_token" => refresh,
          "expires_in" => TOKENTIMETOLIVE
        }.to_json
      else
        halt 401, "Not authorized\n"
      end
    elsif params[:grant_type] == "refresh_token"
      protected!
      refreshToken = params[:refresh_token]
      begin
        token, refresh = refreshToken! refreshToken
        {
          "access_token" => token,
          "token_type" => "bearer",
          "refresh_token" => refresh,
          "expires_in" => TOKENTIMETOLIVE
        }.to_json
      rescue
        halt 401, "Not authorized\n"
      end
    end
  end

  post '/dnd/api/register' do
    data = JSON.parse request.body.read
    user = data["username"]
    pass = data["password"]

    begin
      ensureUser(user,pass)
    rescue
      halt 500, "This user already exists\n"
    end
    ok
  end

  post '/dnd/api/player/:id/pwdReset' do
    protected!
    admin!

    begin
      pass = SecureRandom.urlsafe_base64 8
      hash = BCrypt::Password.create(pass)
      MONGOC[USERS].update_one({ _id: BSON::ObjectId(params[:id]) }, { "$set" => { pwd: hash } })
    rescue
      halt 500, "Could not reset the password of this user..."
    end
    { newPassword: pass }.to_json
  end


  delete '/dnd/api/player/:id' do
    protected!
    admin!

    user = params[:id]
    found = MONGOC[USERS].find(_id: BSON::ObjectId(user))
    if found.count == 1 and found.first()["_id"] == @auth.userid
      halt 403, "Cannot remove your own user\n"
    end

    begin
      MONGOC[USERS].delete_one( _id: BSON::ObjectId(user) )
      ok
    rescue
      halt 500, "Could not remove the provided player"
    end
  end

  put '/dnd/api/player/:id' do
    protected!
    user = params[:id]
    data = JSON.parse request.body.read
    name = data["name"]
    oldPwd = data["oldPwd"]
    newPwd = data["newPwd"]
    found = MONGOC[USERS].find(_id: BSON::ObjectId(user))
    if not found.count == 1
      halt 404, "User not found\n"
    end

    if not pwdOk(found.first()["name"], oldPwd)
      halt 500, "No match with username and old password"
    end

    begin
      hash = BCrypt::Password.create(newPwd)
      MONGOC[USERS].update_one( { _id: BSON::ObjectId(user) } , { "$set" => { name: name, pwd: hash } } )
      ok
    rescue
      halt 500, "Could not update the provided player"
    end
  end

  put '/dnd/api/player/:id/chars' do
    protected!
    admin!

    player = BSON::ObjectId(params[:id])
    chars = JSON.parse request.body.read

    begin
      MONGOC[USERS].find_one_and_update(
        { _id: player },
        { '$set' => { chars: chars } },
        return_document: :after
      )
      ok
    rescue => e
      halt 500, "Could not update the list of characters for the player: #{e}"
    end
  end

  post '/dnd/api/setAdmin' do
    data = JSON.parse request.body.read
    user = BSON::ObjectId(data["user"])
    admin = data["admin"]

    protected!
    admin!

    if user == @auth.userid and not admin
      halt 403, "Cannot toggle yourself to non admin user\n"
    end
    setAdmin(user,admin)
  end

  get '/dnd/api/players' do
    protected!
    admin!
    getPlayers().to_json
  end

  get '/dnd/api/settings' do
    protected!
    user = @auth.userid
    getPlayer(user).to_json
  end

  def updateUser (user)
    clone = user.clone()
    clone.delete "_id"
    result = MONGOC[USERS].find_one_and_replace(
      { name: user["name"] },
      { '$set' => clone },
      return_document: :after
    )
  end

  def getPlayers
    users = MONGOC[USERS].find()

    result = []
    users.each do |user|
      result.push( userResultToPlayer(user) )
    end
    result
  end

  def getPlayer (id)
    user = MONGOC[USERS].find( _id: id ).first()
    userResultToPlayer(user)
  end

  def userResultToPlayer (user)
    {
        :_id => user['_id'].to_str,
        :username => user['name'],
        :isAdmin => user['admin'],
        :chars => getUserChars(user)
    }
  end

  def setAdmin (user, admin = true)
    resp = MONGOC[USERS].find_one_and_update(
      { _id: user },
      { '$set' => { admin: admin }},
      return_document: :after
    )
    ok
  end
end
