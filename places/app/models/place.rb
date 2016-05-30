class Place
  include ActiveModel::Model

  attr_accessor :id, :formatted_address, :location, :address_components

  def initialize(params={})
      if params[:_id]
        @id=params[:_id].to_s
      elsif
        @id=params[:id]
      end
      
      @formatted_address=params[:formatted_address]

      if params[:geometry][:location]
        @location = Point.new(params[:geometry][:location])
      elsif params[:geometry][:geolocation]
        @location = Point.new(params[:geometry][:geolocation])
      end

      if params[:address_components]
        @address_components = []
        params[:address_components].each do |ac| 
          @address_components << AddressComponent.new(ac)
        end
      end
  end

  def persisted? 
    !@id.nil?
  end

  def self.mongo_client
  	Mongoid::Clients.default
  end

  def self.collection
  	self.mongo_client['places']
  end

  def self.load_all file_path
  	file = File.read(file_path)
  	hash = JSON.parse(file)
  	self.collection.insert_many(hash)
  end

  def self.find id
    bson_id = BSON::ObjectId.from_string(id)
    result = self.collection.find(:_id=>bson_id).first
    return result.nil? ? nil : Place.new(result)
  end
  
  def self.find_by_short_name short_name
    self.collection.find(:"address_components.short_name" => short_name)
  end

  def self.to_places locations
    @places = []
    locations.each do |l|
      @places << Place.new(l)
    end
    @places
  end

  def self.all(offset=nil, limit=nil)
    if offset.nil? || limit.nil?
      @places = []
      self.collection.find().each { |e| @places << Place.new(e) }
      @places
    else
      @places = []
      self.collection.find().skip(offset).limit(limit).each { |e| @places << Place.new(e) }
      @places
    end
  end

  def destroy
    id = BSON::ObjectId.from_string(self.id)
    self.class.collection.find(_id:id).delete_one
  end

  # Aggregation Framework Queries
  def self.get_address_components(sort=nil, offset=nil, limit=nil)
    if sort.nil? || offset.nil? || limit.nil?
      self.collection.find().aggregate([
        {:$project => {:_id=>1, :address_components=>1, :formatted_address=>1, :'geometry.geolocation'=>1}}, 
        {:$unwind => '$address_components'}])
    else
      self.collection.find().aggregate([
        {:$project => {:_id=>1, :address_components=>1, :formatted_address=>1, :'geometry.geolocation'=>1}}, 
        {:$unwind => '$address_components'},
        {:$sort => sort},
        {:$skip => offset},
        {:$limit => limit}])
    end
  end

  def self.get_country_names
    result = []
    self.collection.find().aggregate([
        {:$project => {:'address_components.long_name'=>1, :'address_components.types'=>1}},
        {:$unwind => '$address_components'},
        {:$match => {:'address_components.types' => 'country'}},
        {:$group => {:_id => '$address_components.long_name'}}]).to_a.map {|h| result << h[:_id]}
    result
  end

  def self.find_ids_by_country_code country_code
    self.collection.find().aggregate([        
        {:$match => {:'address_components.types' => 'country', :'address_components.short_name' => country_code}},
        {:$project => {:_id=>1}}]).map {|doc| doc[:_id].to_s}
  end

  # Geolocation Queries
  def self.create_indexes
    self.collection.indexes.create_one({ :'geometry.geolocation' => Mongo::Index::GEO2DSPHERE})
  end

  def self.remove_indexes
    self.collection.indexes.drop_all
  end

  def self.near(point, distance=nil)
    if distance.nil?
      self.collection.find(:'geometry.geolocation' => 
      { :$near => {
        :$geometry => point.to_hash,
      }})
    else
      self.collection.find(:'geometry.geolocation' => 
      { :$near => {
        :$geometry => point.to_hash,
        :$maxDistance => distance
      }})
    end
  end

  def near distance=nil
    result_search = self.class.near(@location, distance)
    self.class.to_places(result_search)
  end

  def photos(offset=0, limit=nil)
    photos = []
    Photo.find_photos_for_place(@id).each { |p| photos << Photo.new(p) }
    photos
  end

end
