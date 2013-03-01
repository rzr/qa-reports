class Metric < ActiveRecord::Base
  attr_accessible :group_name, :meego_test_session_id, :name, :unit, :value, :chart
  validates_presence_of :name, :group_name
  belongs_to :meego_test_session

  def find_matching_metric(session)
    session.metric_by_name(group_name, name) unless session.nil?
  end

  # Get metric history for summary graph (i.e. 3 values)
  def get_metric_history
    data = []
    prev = meego_test_session.prev_session
    if prev
      pp = prev.prev_session
      data << find_matching_metric(pp).try(:value)
    end
    data << find_matching_metric(prev).try(:value)
    data << value
    data
  end
end
