class DataMigration
  include Mongoid::Document

  field :version

  store_in client: -> { Thread.current[:mongoid_client_name] || 'default' }
end
