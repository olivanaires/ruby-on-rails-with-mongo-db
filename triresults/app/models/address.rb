class Address
	include Mongoid::Document
	field :city, type: String
	field :state, type: String  
	field :location, as: :loc, type: Point

	def mongoize
		{:city=>"#{city}", :state=>"#{state}", :loc=>location.mongoize}
	end

	def self.demongoize(object)
		case object
		when nil then nil
		when Hash then Address.new({:city=>object[:city], :state=>object[:state], :loc=>object[:loc]})
		when Address then object
		end
	end

	def self.mongoize(object)
		case object
		when nil then nil
		when Hash then object
		when Address then object.mongoize
		end
	end

	def self.evolve(object)
		case object
		when Address then object.mongoize
		else object
		end
	end
end