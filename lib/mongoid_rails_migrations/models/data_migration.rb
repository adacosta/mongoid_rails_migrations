class DataMigration
  include Mongoid::Document

##
# DataMigration *expects* that a string will be acceptable as the _id.  use
# know strategies for recent mongoids WRT allowing the _id to be one. 

  field(:_id, :type => String)

  if respond_to?(:identity)
    begin
      identity(:type => String)
    rescue
      nil
    end
  end

  if respond_to?(:using_object_ids)
    self.using_object_ids = false
  end

  field :version
end
