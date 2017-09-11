class AddOtherPlanSurveySchema < Mongoid::Migration
  def self.up
    SurveySchema.create(:label => 'Other Plan Survey')
  end

  def self.down
    SurveySchema.where(:label => 'Other Plan Survey').first.destroy
  end
end
