#!/usr/bin/ruby

require 'httparty'
require 'json'
require 'bcrypt'
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'

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

COUCH = ENV["COUCH"]
COUCH ||= "http://localhost:5984"
CHARS = "chars"
USERS = "users"
SPELLS = "spells"
ATTACHMENTS = "attachments"

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
    addAllSpells()
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
    resp = getAttachment(name)
    content_type resp.content_type
    resp.body
  end

  get '/dnd/api/players' do
    protected!
    if not isAdmin
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end
    getPlayers()
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
    result = saveCharacter(name,data)
    if result["error"]
      halt 500, "Could not save character: #{result['reason']}\n"
    else
      "ok"
    end
  end

  delete '/dnd/api/char/:name' do
    protected!
    name = params[:name]
    if not canAccessChar(name)
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    result = deleteCharacter(name)
    if result["error"]
      halt 500, "Could not delete character: #{result['reason']}\n"
    else
      "ok"
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

    resp = ensureUser(user,pass)
    if JSON.parse(resp)["error"] == "conflict"
      halt 500, "This user already exists"
    end
    "ok"
  end

  post '/dnd/api/setAdmin' do
    data = JSON.parse request.body.read
    user = data["username"]
    admin = data["admin"]

    !protected
    if not isAdmin
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end
    setAdmin(user,admin)
  end

  get '/dnd/api/chars' do
    protected!
    getCharacters().to_json
  end

  def pwdOk (name, password)
    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
    resp = HTTParty.get("#{COUCH}/#{USERS}/#{name}",
                        :basic_auth => auth)
    resp = JSON.parse(resp)
    
    not resp["pwd"].nil? and BCrypt::Password.new(resp["pwd"]) == password
  end

  def canAccessChar (name)
    user = @auth.credentials[0]

    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
    resp = HTTParty.get("#{COUCH}/#{USERS}/#{user}",
                        :basic_auth => auth)
    resp = JSON.parse(resp)
    not resp["isAdmin"].nil? and resp["isAdmin"] or resp["chars"].include? name
  end

  def isAdmin
    user = @auth.credentials[0]

    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
    resp = HTTParty.get("#{COUCH}/#{USERS}/#{user}",
                        :basic_auth => auth)
    resp = JSON.parse(resp)
    not resp["isAdmin"].nil? and resp["isAdmin"]
  end

  def getPlayers
    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
    resp = HTTParty.get("#{COUCH}/#{USERS}/_all_docs",
                        :query => {:include_docs => true},
                        :basic_auth => auth)
    users = JSON.parse(resp)
    
    result = []
    users['rows'].map do |user|
      result.push user['doc']
    end
    result.to_json
  end

  def getAllCharacters
    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
    resp = HTTParty.get("#{COUCH}/#{CHARS}/_all_docs",
                        :query => { :include_docs => true },
                        :basic_auth => auth)
    list = JSON.parse(resp)
    list = list["rows"].map do |item| 
      item["doc"]
    end
  end

  def getCharacters
    user = @auth.credentials[0]

    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
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

  def getUserChars(userResp)
    list = []
    if not userResp["chars"].nil?
      pwd = ENV["COUCH_PASS"]
      auth = {:username => 'admin', :password => pwd}
      resp = HTTParty.post("#{COUCH}/#{CHARS}/_all_docs",
                           :query => { :include_docs => true },                           
                           :body => { 
                             :keys => userResp["chars"]                          
                           }.to_json,
                           :basic_auth => auth)
      list = JSON.parse(resp)
      newList = []
      list["rows"].map do |item| 
        if not item["doc"].nil? and not item["doc"]["name"].nil?
          newList.push(item["doc"])
        end
      end

      list = newList

      if list.length != userResp["chars"].length
        userChars = list.map do |item|
          item["_id"]
        end
        userResp["chars"] = userChars
        updateUser(userResp)
      end
    end
    list
  end

  def updateUser (user)
    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
    resp = HTTParty.put("#{COUCH}/#{USERS}/#{user['_id']}",
                        :headers => { 'Content-Type' => 'application/json' },
                        :body => user.to_json,
                        :basic_auth => auth)
  end

  def addCharToUser (id)
    user = @auth.credentials[0]

    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
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
    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}

    resp = HTTParty.post("#{COUCH}/#{ATTACHMENTS}/",
                         :headers => { 'Content-Type' => 'application/json' },
                         :body => { 'isAttachment' => true }.to_json,
                         :basic_auth => auth)
    resp = JSON.parse(resp)
    content = file.read

    fileResp = HTTParty.put("#{COUCH}/#{ATTACHMENTS}/#{resp['id']}/attachment",
                            :headers => { 'Content-Type' => type },
                            :query => { :rev => resp['rev'] },
                            :body => content,
                            :basic_auth => auth)
    fileResp = JSON.parse(fileResp)
    fileResp['id']
  end

  def getAttachment (name)
    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
    resp = HTTParty.get("#{COUCH}/#{ATTACHMENTS}/#{name}/attachment",
                        :basic_auth => auth)
    resp
  end

  def getCharacter (name, include=true)
    pwd = ENV["COUCH_PASS"]

    auth = {:username => 'admin', :password => pwd}
    resp = HTTParty.get("#{COUCH}/#{CHARS}/#{name}",
                        :basic_auth => auth)
    JSON.parse(resp)
  end

  def saveCharacter (name, body)
    existing = getCharacter(name, false)
    if not existing.nil?
      body["_rev"] = existing["_rev"]
    end

    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
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
      return "ok"
    end

    body = { :_id => name, :_rev => rev }

    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
    resp = HTTParty.delete("#{COUCH}/#{CHARS}/#{name}",
                           :basic_auth => auth,
                           :query => { "rev" => rev },
                           :headers => { 'Content-Type' => 'application/json' })
    JSON.parse(resp)
  end

  

  def createCharacter (body)
    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
    resp = HTTParty.post("#{COUCH}/#{CHARS}",
                         :basic_auth => auth,
                         :headers => { 'Content-Type' => 'application/json' },
                         :body => body.to_json)
    JSON.parse(resp)
  end

  def getSpells (className)
    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
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
    resp['results'].map do |spell|
      list.push spell['doc']
    end
    list
  end

  def addAllSpells
    rows = []
    CSV.foreach("spells.csv" , { :col_sep => "|", :headers => true } ) do |row|
      object = {}
      row.headers.map do |header|
        object[header] = row[header]
      end
      rows.push object
    end    

    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}

    HTTParty.delete("#{COUCH}/#{SPELLS}",
                    :basic_auth => auth)
    HTTParty.put("#{COUCH}/#{SPELLS}",
                 :basic_auth => auth)
    resp = HTTParty.post("#{COUCH}/#{SPELLS}/_bulk_docs",
                         :basic_auth => auth,
                         :headers => { 'Content-Type' => 'application/json' },
                         :body => {:docs => rows}.to_json)

    filter = addSpellFilter()
    if (resp.code == 200 or resp.code == 201) and (filter == 200 or filter == 201)
      "ok"
    else
      "fail"
    end
  end

  def addSpellFilter
    pwd = ENV["COUCH_PASS"]
    auth = {:username => 'admin', :password => pwd}
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
end

def setAdmin (user, admin = true)
  pwd = ENV["COUCH_PASS"]
  auth = {:username => 'admin', :password => pwd}

  resp = HTTParty.get("#{COUCH}/#{USERS}/#{user}",
                      :basic_auth => auth)
  resp = JSON.parse(resp)
  resp['isAdmin'] = admin
  resp = HTTParty.put("#{COUCH}/#{USERS}/#{user}",
                      :body => resp.to_json,
                      :basic_auth => auth)
  "ok"
end

def ensureUser (user, pass) 
  hash = BCrypt::Password.create(pass)
  
  pwd = ENV["COUCH_PASS"]
  auth = {:username => 'admin', :password => pwd}

  resp = HTTParty.put("#{COUCH}/#{USERS}/#{user}",
                      :body => {:pwd => hash}.to_json,
                      :basic_auth => auth)
end

ensureUser(ENV["ADMIN"],ENV["PASS"])
setAdmin(ENV["ADMIN"], true)

Rack::Handler::WEBrick.run MyServer, webrick_options

