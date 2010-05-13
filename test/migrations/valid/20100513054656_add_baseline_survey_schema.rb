class AddBaselineSurveySchema < Mongoid::Migration
  def self.up
    SurveySchema.create(:label => 'Baseline Survey')
  end

  def self.down
    SurveySchema.where(:label => 'Baseline Survey').first.destroy
  end
end