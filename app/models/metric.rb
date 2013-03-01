class Metric < ActiveRecord::Base
  attr_accessible :group_name, :meego_test_session_id, :name, :unit, :value, :chart
  validates_presence_of :name, :group_name
  belongs_to :meego_test_session

  def find_matching_metric(session)
    session.metric_by_name(group_name, name) unless session.nil?
  end
end
