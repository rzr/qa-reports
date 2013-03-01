class Metric < ActiveRecord::Base
  attr_accessible :group_name, :meego_test_session_id, :name, :unit, :value, :chart
  validates_presence_of :name, :group_name
  belongs_to :meego_test_session
end
