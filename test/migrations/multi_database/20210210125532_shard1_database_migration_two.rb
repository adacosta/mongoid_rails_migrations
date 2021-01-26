class Shard1DatabaseMigrationTwo < Mongoid::Migration
  client :shard1

  def self.up
    SurveySchema.create(:id => 'sharded_migration_two',
                        :label => 'Sharded Survey 2')
  end

  def self.down
    SurveySchema.where(:label => 'Sharded Survey 2').first.destroy
  end
end
