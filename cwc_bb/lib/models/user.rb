module CWC

  class User
    include Mongoid::Document

    field :organization, type: String
    field :first_name,   type: String
    field :last_name,    type: String
    field :phone,        type: String
    field :email,        type: String
    field :apikey,       type: String
    field :activated,    type: Boolean, default:false

    has_many :messages, class_name: 'CWC::Message'

    index :apikey,       unique: true, background: true
    index :email,        unique: true, background: true

    after_create :generate_api_key

    def generate_api_key
      self['apikey'] = Digest::SHA1.hexdigest("#{self['email']}#{self['_id']}")
      save
    end

  end

end
