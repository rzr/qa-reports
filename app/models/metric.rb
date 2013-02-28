class Metric < ActiveRecord::Base
  attr_accessible :group_name, :meego_test_session_id, :name, :unit, :value

  belongs_to :meego_test_session
end
