class DataMigration
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :version
end
