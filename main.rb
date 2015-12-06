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

COUCH = ENV["COUCH"] || "http://localhost:5984"
MONGO ||= "localhost:27017"
CHARS = :chars
USERS = :users
SPELLS = :spells
ATTACHMENTS = :attachments

MONGOC = Mongo::Client.new([ MONGO ], :database => 'dnd')

class MyServer < Sinatra::Base

  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, {:error => "Not authorized"}.to_json
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and pwdOk(@auth.credentials[0], @auth.credentials[1])
    end
  end

  get '/dnd/app/*' do
    send_file File.expand_path('index.html', settings.public_folder)
  end

  get '/dnd/app' do
    send_file File.expand_path('index.html', settings.public_folder)
  end

  get '/dnd/api/test' do
    "Still alive!"
  end

  post '/dnd/api/reload-spells' do
    protected!
    if not isAdmin
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end
    MONGOC[SPELLS].drop
    ensureStore SPELLS
    ensureSpellsIndices()
    addAllSpells()
    ok
  end

  get '/dnd/api/spells/:class' do
    protected!
    className = params[:class]
    getSpells(className).to_json
  end

  get '/dnd/api/spells' do
    protected!
    getSpells(nil).to_json
  end

  post '/dnd/api/image' do
    file = params[:file][:tempfile]
    type = params[:file][:type]
    createAttachment(file,type)
  end

  get '/dnd/api/image/:name' do
    name = params[:name]
    getAttachment(name)
  end

  get '/dnd/api/players' do
    protected!
    if not isAdmin
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end
    getPlayers().to_json
  end

  get '/dnd/api/allchars' do
    protected!
    if not isAdmin
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end
    getAllCharacters().to_json
  end

  get '/dnd/api/char/:name' do
    protected!
    name = params[:name]
    if not canAccessChar(name)
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end
    getCharacter(name).to_json
  end

  put '/dnd/api/char/:name' do
    protected!
    name = params[:name]
    if not canAccessChar(name)
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
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
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
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
    result = createCharacter(data)
    if result["error"]
      halt 500, "could not save character: #{result['reason']}\n"
    else
      id=result["id"]
      res = addCharToUser(id)
      if not res["error"].nil?
        halt 500, "could not add character to user: #{res['reason']}\n"
      else
        id
      end
    end
  end

  post '/dnd/api/register' do
    data = JSON.parse request.body.read
    user = data["username"]
    pass = data["password"]

    begin
      resp = ensureUser(user,pass)
    rescue
      halt 500, "This user already exists\n"
    end
    ok
  end

  delete '/dnd/api/player/:id' do
    protected!
    if not isAdmin
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    user = params[:id]
    if user == @auth.credentials[0]
      halt 403, "Cannot remove your own user\n"
    end

    auth = auth!
    resp = HTTParty.get("#{COUCH}/#{USERS}/#{user}",
                      :basic_auth => auth)
    if resp.code == 200
      rev= JSON.parse(resp)["_rev"]
      resp = HTTParty.delete("#{COUCH}/#{USERS}/#{user}",
                             :query => { "rev" => rev },
                             :basic_auth => auth)
      if resp.code == 200
        ok
      else
        halt 500, "Could not remove the provided player"
      end
    else
      halt 500, "Could not fetch the provided player"
    end
  end

  put '/dnd/api/player/:id/chars' do 
    protected!
    if not isAdmin
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    player = params[:id]
    chars = JSON.parse request.body.read

    auth = auth!
    resp = HTTParty.get("#{COUCH}/#{USERS}/#{player}",
                      :basic_auth => auth)


    if resp.code == 200
      user= JSON.parse(resp)
      user['chars'] = chars
      resp = HTTParty.put("#{COUCH}/#{USERS}/#{player}",
                          :body => user.to_json,
                          :basic_auth => auth)
      if resp.code == 200 or resp.code == 201
        ok
      else
        halt 500, "Could not update the list of characters for the player"
      end
    else
      halt 500, "Could not fetch the provided player 'player'"
    end
  end

  post '/dnd/api/setAdmin' do
    data = JSON.parse request.body.read
    user = data["username"]
    admin = data["admin"]

    protected!
    if not isAdmin
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end
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
    auth = auth!
    resp = MONGOC[USERS].find(name: name)
    if resp.count != 1
      return false
    end
    user = resp.first()
    not user["pwd"].nil? and BCrypt::Password.new(user["pwd"]) == password
  end

  def canAccessChar (name)
    user = @auth.credentials[0]

    auth = auth!
    resp = HTTParty.get("#{COUCH}/#{USERS}/#{user}",
                        :basic_auth => auth)
    resp = JSON.parse(resp)
    not resp["isAdmin"].nil? and resp["isAdmin"] or resp["chars"].include? name
  end

  def isAdmin
    user = @auth.credentials[0]

    auth = auth!
    resp = MONGOC[USERS].find(name: user).first()
    not resp["admin"].nil? and resp["admin"]
  end

  def getPlayers
    auth = auth!
    users = MONGOC[USERS].find()
    
    result = []
    users.each do |user|
      result.push( { :username => user['name'],
        :isAdmin => user['admin'],
        :chars => getUserChars(user)
      })
    end
    result.to_json
  end

  def getAllCharacters
    chars = MONGOC[CHARS].find()
    list = []
    chars.each do |item| 
      list.push item
    end
    list
  end

  def getCharacters
    user = @auth.credentials[0]

    auth = auth!
    resp = HTTParty.get("#{COUCH}/#{USERS}/#{user}",
                        :basic_auth => auth)
    userResp = JSON.parse(resp)

    list = []

    if not userResp["isAdmin"].nil? and userResp["isAdmin"] 
      list = getAllCharacters()
    else
      list = getUserChars(userResp)
    end
    list
  end

  def getUserChars(user)
    chars = []
    if not user["chars"].nil? and not user["chars"].length > 0
      chars = MONGOC[CHARS].find( { _id: { "$in" => user["chars"] } } )

      if chars.count != user["chars"].length
        userChars = []
        chars.each do |char|
          userChars.push char["_id"]
        end
        user["chars"] = userChars
        updateUser(user)
      end
    end
    chars
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

    auth = auth!
    userDesc = HTTParty.get("#{COUCH}/#{USERS}/#{user}",
                            :basic_auth => auth)
    userDesc = JSON.parse(userDesc)
    if userDesc['chars'].nil?
      userDesc['chars'] = []
    end
    userDesc['chars'].push id
    userDesc.delete "_id"

    resp = HTTParty.put("#{COUCH}/#{USERS}/#{user}",
                        :headers => { 'Content-Type' => 'application/json' },
                        :body => userDesc.to_json,
                        :basic_auth => auth)
    JSON.parse(resp)
  end

  def createAttachment (file,type)
    auth = auth!

    grid_file = Mongo::Grid::File.new(file.read, :filename => File.basename(file.path))
    fileResp = MONGOC.database.fs(:fs_name => 'grid').insert_one(grid_file)
    #TODO check
    fileResp['id']
  end

  def getAttachment (name)
    auth = auth!
    #TODO check
    MONGOC.database.fs.download_to_stream(name, io)
  end

  def getCharacter (name, include=true)
    auth = auth!
    resp = HTTParty.get("#{COUCH}/#{CHARS}/#{name}",
                        :basic_auth => auth)
    JSON.parse(resp)
  end

  def saveCharacter (name, body)
    existing = getCharacter(name, false)
    if not existing.nil?
      body["_rev"] = existing["_rev"]
    end

    auth = auth!
    resp = HTTParty.put("#{COUCH}/#{CHARS}/#{name}",
                        :basic_auth => auth,
                        :headers => { 'Content-Type' => 'application/json' },
                        :body => body.to_json)
    JSON.parse(resp)
  end

  def deleteCharacter (name)
    existing = getCharacter(name, false)
    rev = nil
    if not existing.nil?
      rev = existing["_rev"]
    else
      return ok
    end

    body = { :_id => name, :_rev => rev }

    auth = auth!
    resp = HTTParty.delete("#{COUCH}/#{CHARS}/#{name}",
                           :basic_auth => auth,
                           :query => { "rev" => rev },
                           :headers => { 'Content-Type' => 'application/json' })
    JSON.parse(resp)
  end

  

  def createCharacter (body)
    auth = auth!
    resp = HTTParty.post("#{COUCH}/#{CHARS}",
                         :basic_auth => auth,
                         :headers => { 'Content-Type' => 'application/json' },
                         :body => body.to_json)
    JSON.parse(resp)
  end

  def getSpells (className)
    auth = auth!
    resp = HTTParty.get("#{COUCH}/#{SPELLS}/_changes",
                        :basic_auth => auth,
                        :query => {
                          :include_docs => true,
                          :filter => "application/spells",
                          :class => className,
                        },
                        :headers => { 'Content-Type' => 'application/json' })
    resp = JSON.parse(resp)
    list = []
    spells = resp['results'] or []

    spells.map do |spell|
      list.push spell['doc']
    end
    list
  end

end

def setAdmin (user, admin = true)
  resp = MONGOC[USERS].find_one_and_update(
    { name: user },
    { '$set' => { admin: true }},
    return_document: :after
  )
  ok
end

def auth!
  pwd = ENV["COUCHDB_PASS"]
  auth = {:username => 'admin', :password => pwd}
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
end

def ensureIndices
  ensureUsersIndices()
  ensureSpellsIndices()
end

def ensureUsersIndices
  MONGOC[USERS].indexes.create_one({ name: 1 }, unique: true)
end

def ensureStore (store)
  collection = MONGOC[store]
  try do
    collection.create()
  end
end

def addAllSpells
  rows = []
  CSV.foreach("spells.csv" , { :col_sep => "|", :headers => true } ) do |row|
    object = {}
    row.headers.map do |header|
      object[header] = row[header]
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
      { key: { name: "text", description: "text"} , weights: { name: 10, description: 1 } , name: "spell_text_index" }
    ])
  end
end

def addSpellFilter
  auth = auth!
  resp = HTTParty.put("#{COUCH}/#{SPELLS}/_design/application",
                      :basic_auth => auth,
                      :headers => { 'Content-Type' => 'application/json' },
                      :body => {
                        :filters => {
                          :spells => "function(doc,req) { if(doc.class && (!req.query.class || doc.class.toLowerCase().indexOf(req.query.class.toLowerCase())>=0)){ return true; } else { return false; } }"
                        }
                      }.to_json)
  resp.code
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

