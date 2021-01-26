class SurveySchema
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in client: -> { Thread.current[:mongoid_client_name]  || 'default' }

  field :label
end
