class Event
	include Mongoid::Document

	field :o, as: :order, type: Integer
	field :n, as: :name, type: String
	field :d, as: :distance, type: Float
	field :u, as: :units, type: String

	embedded_in :parent, polymorphic: true, touch: true

	validates_presence_of :order, :name

	def meters
		case u
		when "meters"
			return d
		when "kilometers"
			return d * 1000
		when "yards"
			return d * 0.9144
		when "miles"
			return d * 1609.344
	 	else
	 		return nil
		end
	end

	def miles
		case u
		when "miles"
			return d
		when "meters"
			return d * 0.000621371
		when "kilometers"
			return d * 0.621371
		when "yards"
			return d * 0.000568182
	 	else
	 		return nil
		end
	end

end
