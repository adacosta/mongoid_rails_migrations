class DefaultDatabaseMigrationTwo < Mongoid::Migration
  def self.up
    SurveySchema.find_or_create_by(:id => 'default_migration two',
                        :label => 'Default Survey 2')
  end

  def self.down
    SurveySchema.where(:label => 'Default Survey 2').first.destroy
  end
end
