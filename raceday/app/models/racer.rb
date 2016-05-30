class Racer
  include ActiveModel::Model

  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  def persisted?
    !@id.nil?
  end

  def created_at
    nil
  end

  def updated_at
    nil
  end

  def initialize(params={})
    @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @gender=params[:gender]
    @group=params[:group]
    @secs=params[:secs].to_i
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    self.mongo_client['racers']
  end

  def self.all(prototype={}, sort={}, offset=0, limit=1000)
    tmp = {}
    limit = 1000 if limit.nil?

    sort.each { |k,v|
      tmp[k] = v if [:number, :first_name, :last_name, :gender, :group, :secs].include?(k)
    }

    sort=tmp
    prototype.each_with_object({}) {|(k,v), tmp| tmp[k.to_sym] = v; tmp}
    collection.find(prototype).sort(tmp).skip(offset).limit(limit)
  end

  def self.paginate(params)
    page=(params[:page] ||= 1).to_i
    limit=(params[:per_page] ||= 30).to_i
    offset=(page-1)*limit

    racers=[]
    all({}, {}, offset, limit).each { |doc| racers << Racer.new(doc) }

    total=all({}, {}, 0, 1).count

    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end
  end

  def self.find id
    id = BSON::ObjectId.from_string(id) if id.is_a?(String)
    result=collection.find(_id: id).first
    return result.nil? ? nil : Racer.new(result)
  end

  def save
    p self.number
    result=self.class.collection.insert_one(number: self.number, first_name: self.first_name,
      last_name:self.last_name, gender:self.gender, group:self.group, secs:self.secs)
    @id=result.inserted_id
  end

  def update params
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @group=params[:group]
    @gender=params[:gender]
    @got=params[:got]
    @secs=params[:secs].to_i

    params.slice!(:number, :first_name, :last_name, :gender, :group, :secs) if !params.nil?

    id = BSON::ObjectId.from_string(self.id)
    self.class.collection.find(_id:id).update_one(params)
  end

  def destroy
    id = BSON::ObjectId.from_string(self.id)
    self.class.collection.find(_id:id).delete_one
  end

end
