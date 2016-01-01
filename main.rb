#!/usr/bin/ruby

require 'httparty'
require 'json'
require 'bcrypt'
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'mongo'

CERT_PATH = 'certificates/'

webrick_options = {
        :Port               => 8443,
        :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
        :DocumentRoot       => "/ruby/htdocs",
        :SSLEnable          => true,
        :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
        :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open(File.join(CERT_PATH, "server.crt")).read),
        :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open(File.join(CERT_PATH, "server.key")).read),
        :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
}

MONGO = ENV["MONGO"] || "localhost:27017"
CHARS = :chars
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
        @auth.credentials = [token[:user]]
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

      if pwdOk(user, pwd)
        token = token! user
        {
          "access_token" => token,
          "token_type" => "bearer",
          "expires_in" => TOKENTIMETOLIVE
        }.to_json
      else
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
    user = @auth.credentials[0]
    getPlayer(user).to_json
  end

  get '/dnd/api/allchars' do
    protected!
    admin!
    getAllCharacters().to_json
  end

  get '/dnd/api/char/:name' do
    protected!
    name = params[:name]
    if not canAccessChar(name)
      noAccess
    end
    getCharacter(name).to_json
  end

  put '/dnd/api/char/:name' do
    protected!
    name = params[:name]
    if not canAccessChar(name)
      noAccess
    end

    data = JSON.parse request.body.read
    begin
      saveCharacter(name,data)
    rescue => e
      halt 500, "Could not save character: #{e}"
    end
    ok
  end

  delete '/dnd/api/char/:name' do
    protected!
    name = params[:name]
    if not canAccessChar(name)
      noAccess
    end

    begin
      result = deleteCharacter(name)
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
      id = character["_id"].to_str
      addCharToUser(id)
      { id: id }.to_json
    rescue => e
      halt 500, "could not save character: #{e}\n"
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

  delete '/dnd/api/player/:id' do
    protected!
    admin!

    user = params[:id]
    found = MONGOC[USERS].find(_id: BSON::ObjectId(user))
    if found.count == 1 and found.first()["name"] == @auth.credentials[0]
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
      halt 500, "No match with old username and password"
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

    player = params[:id]
    chars = JSON.parse request.body.read

    begin
      MONGOC[USERS].find_one_and_update(
        { name: player },
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
    user = data["username"]
    admin = data["admin"]

    protected!
    admin!

    if user == @auth.credentials[0] and not admin
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
      not user["pwd"].nil? and BCrypt::Password.new(user["pwd"]) == password
    rescue
      false
    end
  end

  def canAccessChar (id)
    user = @auth.credentials[0]

    resp = MONGOC[USERS].find(name: user).first()
    (not resp["admin"].nil? and resp["admin"]) or resp["chars"].include? id
  end

  def isAdmin
    user = @auth.credentials[0]

    resp = MONGOC[USERS].find(name: user).first()
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

  def getPlayer (name)
    user = MONGOC[USERS].find( name: name ).first()
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
    chars = MONGOC[CHARS].find()
    list = []
    chars.each do |item| 
      item["_id"] = item["_id"].to_str
      list.push item
    end
    list
  end

  def getCharacters
    user = @auth.credentials[0]
    userResp = MONGOC[USERS].find( name: user ).first()
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
    user = @auth.credentials[0]

    userDesc = MONGOC[USERS].find(name: user).first()
    if userDesc['chars'].nil?
      userDesc['chars'] = []
    end
    userDesc['chars'].push id

    MONGOC[USERS].find_one_and_update(
      { name: user },
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
    { name: user },
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
  ensureStore ATTACHMENTS
  ensureStore TOKENS
end

def ensureIndices
  ensureUsersIndices()
  ensureSpellsIndices()
  ensureTokenIndices()
end

def ensureUsersIndices
  MONGOC[USERS].indexes.create_one({ name: 1 }, unique: true)
end

def ensureTokenIndices
  try do
    MONGOC[TOKENS].indexes.create_many([
      { key: { user: 1 }, unique: true, name: "tokens_main_index"},
      { key: { token: 1 }, unique: true, name: "tokens_unique_index"},
      { key: { token: 1, user: 1, created: 1 }, name: "tokens_index"}
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
  existing = MONGOC[TOKENS].delete_many(user: user)
  puts "deleted #{existing} tokens..."
  MONGOC[TOKENS].insert_one(user: user, token: token, created: (Time.new).to_i)
  token
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
  ensureUser(ADMIN,ENV["PASS"] || "secret")
rescue
  puts "admin user already exists"
end
addAllSpells()
setAdmin(ADMIN, true)

Rack::Handler::WEBrick.run MyServer, webrick_options

