class AddSecondSurveySchema < Mongoid::Migration
  def self.up
    SurveySchema.create(:label => 'First Survey')
  end

  def self.down
    SurveySchema.where(:label => 'First Survey').first.destroy
  end
end

