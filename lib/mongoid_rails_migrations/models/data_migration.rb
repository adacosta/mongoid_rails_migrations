class DataMigration
  include Mongoid::Document
  include Mongoid::Timestamps

  field :version
end