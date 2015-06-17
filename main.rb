#!/usr/bin/ruby

require 'httparty'
require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require 'pry'
require 'bcrypt'

COUCH = "http://localhost:5984"
CHARS = "chars"
USERS = "users"

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and pwdOk(@auth.credentials[0], @auth.credentials[1])
  end
end

configure do
  enable :cross_origin
  set :allow_methods, [:get, :post, :options, :delete, :put]
end

get '/dnd/app/*' do
  send_file File.expand_path('index.html', settings.public_folder)
end

get '/dnd/api/test' do
  "Still alive!"
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
  if saveCharacter(name,data)["error"]
    halt 500, "Could not save character: #{result['reason']}\n"
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
  user = data["user"]
  pass = data["password"]

  hash = BCrypt::Password.create(pass)
  
  pwd = ENV["COUCH_PASS"]

  auth = {:username => 'admin', :password => pwd}
  resp = HTTParty.put("#{COUCH}/#{USERS}/#{user}",
                       :body => {:pwd => hash}.to_json,
                       :basic_auth => auth)
  JSON.parse(resp).to_json
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

def getCharacters
  user = @auth.credentials[0]

  pwd = ENV["COUCH_PASS"]
  auth = {:username => 'admin', :password => pwd}
  resp = HTTParty.get("#{COUCH}/#{USERS}/#{user}",
                      :basic_auth => auth)
  resp = JSON.parse(resp)

  list = []

  if not resp["isAdmin"].nil? and resp["isAdmin"] 
    resp = HTTParty.get("#{COUCH}/#{CHARS}/_all_docs",
                        :query => { :include_docs => true },
                        :basic_auth => auth)
    list = JSON.parse(resp)
    list = list["rows"].map do |item| 
      item["doc"]
    end
  elsif not resp["chars"].nil?
    resp = HTTParty.post("#{COUCH}/#{CHARS}/_all_docs",
                         :query => { :include_docs => true },                           
                         :body => { 
                           :keys => resp["chars"]                          
                         }.to_json,
                         :basic_auth => auth)
    list = JSON.parse(resp)
    list = list["rows"].map do |item| 
      item["doc"]
    end
  end

  list  
end

def addCharToUser (id)
  user = @auth.credentials[0]

  pwd = ENV["COUCH_PASS"]
  auth = {:username => 'admin', :password => pwd}
  userDesc = HTTParty.get("#{COUCH}/#{USERS}/#{user}",
                      :basic_auth => auth)
  binding.pry
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


def isAdmin(user)
  user = @auth.credentials[0]

  not resp["isAdmin"].nil? and resp["isAdmin"]
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

def createCharacter (body)
  pwd = ENV["COUCH_PASS"]
  auth = {:username => 'admin', :password => pwd}
  resp = HTTParty.post("#{COUCH}/#{CHARS}",
                       :basic_auth => auth,
                       :headers => { 'Content-Type' => 'application/json' },
                       :body => body.to_json)
  JSON.parse(resp)
end
