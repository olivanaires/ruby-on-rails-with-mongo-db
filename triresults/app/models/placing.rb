class Placing
	include Mongoid::Document
	field :name, type: String
	field :place, type: Integer  

	def mongoize
		{:name=>"#{name}", :place=>place}
	end

	def self.demongoize(object)
		case object
		when nil then nil
		when Hash then Placing.new(:name=>object[:name], :place=>object[:place])
		when Placing then object
		end
	end

	def self.mongoize(object)
		case object
		when nil then nil
		when Hash then object
		when Placing then object.mongoize
		end
	end

	def self.evolve(object)
		case object
		when Placing then object.mongoize
		else object
		end
	end
	
end