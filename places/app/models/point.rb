class Point

  attr_accessor :longitude, :latitude

  def initialize(params={})
  	if params[:lng] && params[:lat]
  		@longitude=params[:lng]
  		@latitude=params[:lat]
  	elsif params[:coordinates]
  		@longitude=params[:coordinates][0]
  		@latitude=params[:coordinates][1]
  	end
  end

  def to_hash
  	hash = Hash.new(0)
  	hash[:type]="Point"
  	hash[:coordinates]=[@longitude, @latitude]
  	hash
  end
end
