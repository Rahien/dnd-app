class MyServer
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
