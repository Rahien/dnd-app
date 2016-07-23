def addItemOwners (items)
  ownerIds = []
  items.map do |item|
    owner = item["owner"]
    if not owner.respond_to? 'each'
      ownerIds.push BSON::ObjectId(owner)
    else
      ownerIds.concat owner
    end
  end

  owners = MONGOC[USERS].find( { _id: { "$in" => ownerIds } } )
  ownerHash = {}
  owners.each do |owner|
    owner.delete "pwd"
    owner["_id"] = owner["_id"].to_str
    ownerHash[owner["_id"]] = owner
  end

  items.map do |item|
    owner = item["owner"]
    if not owner.respond_to? 'each'
      item["owner"] = ownerHash[owner.to_str]
    else
      item["owner"] = owner.each do |one|
        ownerHash[one.to_str]
      end
    end
  end
end
