class Shard1DatabaseMigration < Mongoid::Migration
  client :shard1

  def self.up
    SurveySchema.create(:id => 'sharded_migration',
                        :label => 'Sharded Survey')
  end

  def self.down
    SurveySchema.where(:label => 'Sharded Survey').first.destroy
  end
end
