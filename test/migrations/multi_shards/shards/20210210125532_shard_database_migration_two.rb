class ShardDatabaseMigrationTwo < Mongoid::Migration
  def self.up
    SurveySchema.find_or_create_by(:id => 'sharded_migration_two',
                        :label => 'Sharded Survey 2')
  end

  def self.down
    SurveySchema.where(:label => 'Sharded Survey 2').first.destroy
  end
end
