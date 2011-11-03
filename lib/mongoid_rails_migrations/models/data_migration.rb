class DataMigration
  include Mongoid::Document

##
# life gets harder when the id isn't a string...

  field(:_id, :type => String, :default => proc{ App.uuid })

  if respond_to?(:identity)
    begin
      identity(:type => String, :default => proc{ App.uuid })
    rescue
      nil
    end
  end

  if respond_to?(:using_object_ids)
    self.using_object_ids = false
  end

  field :version
end
