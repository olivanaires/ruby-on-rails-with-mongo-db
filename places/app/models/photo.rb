class Photo
  
  attr_accessor :id, :location
  attr_writer :contents

  def initialize(params={})
  	if params[:_id]
  		@id=params[:_id].to_s
  	elsif
  		@id=params[:id]
  	end
 
  	if params[:metadata]
  		if params[:metadata][:location]
  			@location = Point.new(params[:metadata][:location])
  		end
  	end

    if params[:metadata]
      if params[:metadata][:place]
        @place = params[:metadata][:place]
      end
    end
  end

  def self.mongo_client
  	Mongoid::Clients.default
  end

  def persisted?
  	!@id.nil?
  end

  def save
  	if !persisted?
  		description = {}
  		loc = EXIFR::JPEG.new(@contents).gps
  		@contents.rewind
      @location=Point.new(:lng=>loc.longitude, :lat=>loc.latitude)
  		description[:content_type] = "image/jpeg"
  		description[:metadata] = {}
  		description[:metadata][:location] = @location.to_hash
      description[:metadata][:place] = @place
  		grid_file = Mongo::Grid::File.new(@contents.read, description)
  		id = self.class.mongo_client.database.fs.insert_one(grid_file)
  		@id=id.to_s
  	else
      place = (@place.is_a?(String) && BSON::ObjectId.from_string(@place)) || @place
      self.class.mongo_client.database.fs.find(_id:BSON::ObjectId.from_string(@id))
        .update_one(:metadata => {:location => @location.to_hash, :place => place})
    end
  end

  def self.all(offset=0, limit=nil)
  	if limit.nil?
      mongo_client.database.fs.find().skip(offset).map {|doc| Photo.new(doc) }
    else
      mongo_client.database.fs.find().skip(offset).limit(limit).map {|doc| Photo.new(doc) }
    end
  end

  def self.find id
    f=mongo_client.database.fs.find(_id:BSON::ObjectId.from_string(id)).first
    return f.nil? ? nil : Photo.new(f)
  end

  def contents
    tmp = ""
    grid_file=self.class.mongo_client.database.fs.find_one(:_id=>BSON::ObjectId.from_string(@id))
    grid_file.chunks.reduce([]) {|x,chunk| tmp <<  chunk.data.data}
    tmp
  end

  def destroy
    self.class.mongo_client.database.fs.find(_id:BSON::ObjectId.from_string(@id)).delete_one
  end

  def find_nearest_place_id max_distance
    result = Place.near(@location, max_distance).first
    result[:_id]
  end

  def self.find_photos_for_place id
    place_id = (id.is_a?(String) && BSON::ObjectId.from_string(id)) || id
    self.mongo_client.database.fs.find(:'metadata.place' => place_id)
  end

  def place
    @place.nil? ? nil : Place.find(@place.to_s)
  end

  def place= place
    @place = (place.is_a?(Place) && place.id) || place
  end

end
