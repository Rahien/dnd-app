#!/usr/bin/ruby

require 'httparty'
require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require 'pry'
require 'bcrypt'

couch = "http://localhost:5984"

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

get '/dnd/test' do
  "Still alive!"
end

get '/dnd/char/:name' do
  protected!
  name = params[:name]
  if not canAccessChar(name)
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end
  "ok"
end

put '/dnd/char/:name' do
  protected!
  name = params[:name]
  if not canAccessChar(name)
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  data = JSON.parse request.body.read
end

post '/dnd/chars' do
  # TODO create character
  data = JSON.parse request.body.read
end

post '/dnd/register' do
  data = JSON.parse request.body.read
  user = data["user"]
  pass = data["password"]

  hash = BCrypt::Password.create(pass)
  
  pwd = ENV["COUCH_PASS"]

  auth = {:username => 'admin', :password => pwd}
  resp = HTTParty.put("http://localhost:5984/users/#{user}",
                       :body => {:pwd => hash}.to_json,
                       :basic_auth => auth)
  JSON.parse(resp).to_json
end

get '/dnd/chars' do
  protected!
  getCharacters().to_json
end

def pwdOk (name, password)
  pwd = ENV["COUCH_PASS"]
  auth = {:username => 'admin', :password => pwd}
  resp = HTTParty.get("http://localhost:5984/users/#{name}",
                       :basic_auth => auth)
  resp = JSON.parse(resp)
  
  not resp["pwd"].nil? and BCrypt::Password.new(resp["pwd"]) == password
end

def canAccessChar (name)
  user = @auth.credentials[0]

  pwd = ENV["COUCH_PASS"]
  auth = {:username => 'admin', :password => pwd}
  resp = HTTParty.get("http://localhost:5984/users/#{user}",
                      :basic_auth => auth)
  resp = JSON.parse(resp)
  not resp["isAdmin"].nil? and resp["isAdmin"] or resp["chars"].include? name
end

def getCharacters
  user = @auth.credentials[0]

  pwd = ENV["COUCH_PASS"]
  auth = {:username => 'admin', :password => pwd}
  resp = HTTParty.get("http://localhost:5984/users/#{user}",
                      :basic_auth => auth)
  resp = JSON.parse(resp)

  list = []

  if not resp["isAdmin"].nil? and resp["isAdmin"] 
    resp = HTTParty.get("http://localhost:5984/test/_all_docs",
                        :query => { :include_docs => true },
                        :basic_auth => auth)
    list = JSON.parse(resp)
    list = list["rows"].map do |item| 
      item["doc"]
    end
  elsif not resp["chars"].nil?
    resp = HTTParty.post("http://localhost:5984/test/_all_docs",
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

def isAdmin(user)
  user = @auth.credentials[0]

  not resp["isAdmin"].nil? and resp["isAdmin"]
end

def getDocument (doc, include=true)
  pwd = ENV["COUCH_PASS"]

  auth = {:username => 'admin', :password => pwd}
  resp = HTTParty.get("http://localhost:5984/test/#{doc}",
                      :basic_auth => auth)
  JSON.parse(resp)
end

def saveDocument (body)
  existing = getDocument(doc, false)
  if not existing.nil?
    body["_rev"] = existing["_rev"]
  end
  id = body["_id"]

  pwd = ENV["COUCH_PASS"]
  auth = {:username => 'admin', :password => pwd}
  resp = HTTParty.put("http://localhost:5984/test/#{id}",
                      :basic_auth => auth,
                      :body => body.to_json)
  JSON.parse(resp).to_json
end
