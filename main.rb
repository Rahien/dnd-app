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
MONSTERS = :monsters
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

    def isAdmin
      user = @auth.userid

      resp = MONGOC[USERS].find(_id: user).first()
      not resp["admin"].nil? and resp["admin"]
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

end

def ensureUser (user, pass) 
  hash = BCrypt::Password.create(pass)
  MONGOC[USERS].insert_one({ name: user, pwd: hash })
end

def ensureStores
  ensureStore USERS
  ensureStore MONSTERS
  ensureStore SPELLS
  ensureStore CHARS
  ensureStore ADVENTURES
  ensureStore ATTACHMENTS
  ensureStore TOKENS
end

def ensureIndices
  ensureUsersIndices()
  ensureMonsterIndices()
  ensureCharacterIndices()
  ensureAdventureIndices()
  ensureSpellsIndices()
  ensureTokenIndices()
end

def ensureUsersIndices
  MONGOC[USERS].indexes.create_one({ name: 1 }, unique: true)
end

def ensureMonsterIndices
  MONGOC[MONSTERS].indexes.create_many([
    { key: { name: 1 }, unique: true, name: "monsters_main_index"},
    { key: { name: 1, cr: 1, size: 1, type: 1, align: 1, owner: 1 }, name: "monsters_projection_index"}, 
    { key: { name: "text", description: "text", actions: "text", traits: "text", legendary: "text", reactions: "text"} , weights: { name: 10, description: 1, traits: 1, actions: 1, legendary: 1, reactions: 1 } , name: "monster_text_index" }
  ])
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

def ensureSpellsIndices
  try do
    MONGOC[SPELLS].indexes.create_many([
      { key: { name: 1 }, unique: true, name: "spell_main_index"},
      { key: { class: 1 }, name: "spell_class_index"},
      { key: { name: "text", description: "text"} , weights: { name: 10, description: 1 } , name: "spell_text_index" }
    ])
  end
end

def ensureStore (store)
  collection = MONGOC[store]
  try do
    collection.create()
  end
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

require_relative "sinatra/util.rb"
require_relative "sinatra/players.rb"
require_relative "sinatra/chars.rb"
require_relative "sinatra/spells.rb"
require_relative "sinatra/adventures.rb"
require_relative "sinatra/attachments.rb"
require_relative "sinatra/monsters.rb"

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

