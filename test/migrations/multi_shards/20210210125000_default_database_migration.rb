class DefaultDatabaseMigration < Mongoid::Migration
  def self.up
    SurveySchema.find_or_create_by(:id => 'default_migration',
                        :label => 'Default Survey')
  end

  def self.down
    SurveySchema.where(:label => 'Default Survey').first.destroy
  end
end
