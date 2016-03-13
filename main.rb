#!/usr/bin/ruby

require 'httparty'
require 'json'
require 'bcrypt'
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'mongo'

webrick_options = {
        :Port               => 80,
        :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
        :DocumentRoot       => "/ruby/htdocs",
}

MONGO = ENV["MONGO"] || "localhost:27017"
CHARS = :chars
ADVENTURES = :adventures
USERS = :users
SPELLS = :spells
TOKENS = :tokens
ATTACHMENTS = :attachments
TOKENTIMETOLIVE = (ENV["TOKENTIME"] || 3600).to_i

MONGOC = Mongo::Client.new([ MONGO ], :database => 'dnd')

class MyServer < Sinatra::Base
  before do
    content_type 'application/json'
  end

  set :protection, :except => [:json_csrf]

  helpers do
    def protected!
      return if hasToken?
      halt 400, {:error => "invalid_grant"}.to_json
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and pwdOk(@auth.credentials[0], @auth.credentials[1])
    end

    def admin!
      if not isAdmin
        noAccess
      end
    end

    def noAccess
      halt 401, {error: "unauthorized_client",error_description: "The user is invalid or is not allowed to make this request."}.to_json
    end

    def hasToken?
      token = (request.env["HTTP_AUTHORIZATION"] and request.env["HTTP_AUTHORIZATION"].partition(" ").last())
      token = findToken token
      if token
        @auth = OpenStruct.new
        @auth.userid = BSON::ObjectId(token[:user])
      else
        false
      end
    end
  end

  error 404 do
    redirect to("/dnd/app")
  end

  get '/dnd/app/*' do
    content_type 'text/html'
    send_file File.expand_path('index.html', settings.public_folder)
  end

  get '/dnd/app' do
    content_type 'text/html'
    send_file File.expand_path('index.html', settings.public_folder)
  end

  get '/dnd/api/test' do
    { ok: "Still alive!" }.to_json
  end

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

  post '/dnd/api/reload-spells' do
    protected!
    admin!
    MONGOC[SPELLS].drop
    ensureStore SPELLS
    ensureSpellsIndices()
    addAllSpells()
    ok
  end

  get '/dnd/api/spells' do
    protected!
    search = params[:search]
    kind = params[:class]
    getSpells(search, kind).to_json
  end

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
    unless ownsAdventure?(adventure)
      adventure.delete "dmNotes"
    end
    addAdventureOwners([adventure])
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

  get '/dnd/api/chars' do
    protected!
    getCharacters().to_json
  end

  def pwdOk (name, password)
    resp = MONGOC[USERS].find(name: name)
    if resp.count != 1
      return false
    end
    user = resp.first()
    begin
      if not user["pwd"].nil? and BCrypt::Password.new(user["pwd"]) == password
        user["_id"].to_str
      else
        false
      end
    rescue
      false
    end
  end

  def canAccessChar (id)
    user = @auth.userid

    resp = MONGOC[USERS].find(_id: user).first()
    (not resp["admin"].nil? and resp["admin"]) or resp["chars"].include? id
  end

  def ownsAdventure? (adventure)
    user = @auth.userid
    (adventure["owner"] == user) or isAdmin
  end

  def fetchAdventure (id)
    found = MONGOC[ADVENTURES].find(_id: BSON::ObjectId(params['id']))
    if not found.count == 1
      halt 404, "Adventure not found\n"
    end

    adventure = found.first()
  end

  def isAdmin
    user = @auth.userid

    resp = MONGOC[USERS].find(_id: user).first()
    not resp["admin"].nil? and resp["admin"]
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

  def getAdventures
    adventures = nil
    if isAdmin
      adventures = getAllAdventures()
    else
      user = @auth.userid
      adventures = getUserAdventures(user)
    end

    addAdventureOwners(adventures)
    adventures
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

  def getAllAdventures
    advs = []
    MONGOC[ADVENTURES].find().projection( name: 1, date: 1, owner: 1 ).each do |adv|
      adv["_id"] = adv["_id"].to_str
      advs.push adv
    end
    advs
  end

  def addAdventureOwners (adventures)
    ownerIds = adventures.map do |adv|
      BSON::ObjectId(adv["owner"])
    end

    owners = MONGOC[USERS].find( { _id: { "$in" => ownerIds } } )
    ownerHash = {}
    owners.each do |owner|
      owner.delete "pwd"
      owner["_id"] = owner["_id"].to_str
      ownerHash[owner["_id"]] = owner
    end

    adventures.map do |adv|
      adv["owner"] = ownerHash[adv["owner"].to_str]
    end
  end

  def getUserAdventures (userId)
    adventures = []
    userResp = MONGOC[USERS].find( _id: userId ).first()
    chars = userResp["chars"]
    result = MONGOC[ADVENTURES].find( { chars: { "$elemMatch" => { "_id" => { "$in" => chars } } } } ).projection( name: 1, date: 1, owner: 1 )
    result.each do |adv|
      adv["_id"] = adv["_id"].to_str
      adventures.push adv
    end
    adventures
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

  def createAttachment (file,type)
    grid_file = Mongo::Grid::File.new(file.read, :filename => File.basename(file.path))
    fileId = MONGOC.database.fs.insert_one(grid_file)
    fileId.to_str
  end

  def getAttachment (name)
    result = MONGOC.database.fs.find_one(:_id => BSON::ObjectId(name))
    result.data
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

  def createAdventure (body)
    body["owner"] = @auth.userid

    result = MONGOC[ADVENTURES].insert_one(body)
    body['_id'] = result.inserted_id.to_str
    body
  end

  def getSpells (search, className)
    params = {
      '$text' => { '$search' => search }
    }
    if not className.nil?
      params['class'] = className
    end

    resp = MONGOC[SPELLS].find( params )
                         .projection( { score: { '$meta' => 'textScore' } } )
                         .sort( { score: { '$meta' => 'textScore' } } )

    list = []
    resp.each do |spell|
      spell.delete '_id'
      spell.delete 'score'
      list.push spell
    end
    list
  end

end

def setAdmin (user, admin = true)
  resp = MONGOC[USERS].find_one_and_update(
    { _id: user },
    { '$set' => { admin: admin }},
    return_document: :after
  )
  ok
end

def ensureUser (user, pass) 
  hash = BCrypt::Password.create(pass)
  MONGOC[USERS].insert_one({ name: user, pwd: hash })
end

def ensureStores
  ensureStore USERS
  ensureStore SPELLS
  ensureStore CHARS
  ensureStore ADVENTURES
  ensureStore ATTACHMENTS
  ensureStore TOKENS
end

def ensureIndices
  ensureUsersIndices()
  ensureCharacterIndices()
  ensureAdventureIndices()
  ensureSpellsIndices()
  ensureTokenIndices()
end

def ensureUsersIndices
  MONGOC[USERS].indexes.create_one({ name: 1 }, unique: true)
end

def ensureCharacterIndices
  # covered query
  MONGOC[CHARS].indexes.create_one({ name: 1, level: 1, race: 1, class: 1 })
end

def ensureAdventureIndices
  # covered query
  MONGOC[ADVENTURES].indexes.create_one({ name: 1, date: 1, owner: 1 })
end

def ensureTokenIndices
  try do
    MONGOC[TOKENS].indexes.create_many([
      { key: { user: 1 }, unique: true, name: "tokens_main_index"},
      { key: { token: 1 }, unique: true, name: "tokens_unique_index"},
      { key: { token: 1, user: 1, created: 1, refresh: 1 }, name: "tokens_index"}
    ])
  end
end

def ensureStore (store)
  collection = MONGOC[store]
  try do
    collection.create()
  end
end

def findToken (token)
  found = MONGOC[TOKENS].find(token: token).projection({ token: 1, user: 1, created: 1, _id: 1 })
  if found.count == 1
    token = found.first()
    if ((Time.new).to_i) - token["created"] > TOKENTIMETOLIVE
      MONGOC[TOKENS].delete_one( { _id: token["_id"] } )
      return false
    else
      return { user: token["user"], token: token["token"] }
    end
  else
    return false
  end
end

def token! (user)
  token = SecureRandom.uuid()
  refresh = SecureRandom.uuid()
  existing = MONGOC[TOKENS].delete_many(user: user)
  puts "deleted #{existing} tokens..."
  MONGOC[TOKENS].insert_one(user: user, token: token, refresh: refresh, created: (Time.new).to_i)
  [token, refresh]
end

def refreshToken! (refresh)
  found = MONGOC[TOKENS].find(refresh: refresh).projection({ token: 1, user: 1, created: 1, _id: 1 })
  if found.count == 1
    result = found.first()
    if  ((Time.new).to_i) - result["created"] <= TOKENTIMETOLIVE
      token, refresh = token! result["user"]
      [token, refresh]
    else
      throw "could not refresh token"
    end
  else
    throw "could not refresh token"
  end
end


def addAllSpells
  rows = []
  CSV.foreach("spells.csv" , { :col_sep => "|", :headers => true } ) do |row|
    object = {}
    row.headers.map do |header|
      object[header] = row[header]
    end
    object["class"] = object["class"].split(",").map do |item|
      item.strip()
    end
    rows.push({ insert_one: object })
  end

  inserted = 0
  begin
    result = MONGOC[SPELLS].bulk_write(rows, ordered: false)
    inserted = result.inserted_count
  rescue => e
    inserted = e.result['n']
  end
  puts "inserted #{inserted} new spells, did not replace #{rows.length - inserted} existing ones."
end

def ensureSpellsIndices
  try do
    MONGOC[SPELLS].indexes.create_many([
      { key: { name: 1 }, unique: true, name: "spell_main_index"},
      { key: { class: 1 }, name: "spell_class_index"},
      { key: { name: "text", description: "text"} , weights: { name: 10, description: 1 } , name: "spell_text_index" }
    ])
  end
end

def try(&block)
  begin
    yield
  rescue
    # give up
  end
end

def ok
  { success: true }.to_json
end

ensureStores()
ensureIndices()
ADMIN = ENV["ADMIN"] || "admin"
begin
  result = ensureUser(ADMIN,ENV["PASS"] || "secret")
  setAdmin(result.inserted_id, true)
rescue
  puts "admin user already exists"
end
addAllSpells()

Rack::Handler::WEBrick.run MyServer, webrick_options

