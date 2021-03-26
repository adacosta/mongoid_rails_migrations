class ShardDatabaseMigration < Mongoid::Migration
  def self.up
    SurveySchema.find_or_create_by(:id => 'sharded_migration',
                        :label => 'Sharded Survey')
  end

  def self.down
    SurveySchema.where(:label => 'Sharded Survey').first.destroy
  end
end
