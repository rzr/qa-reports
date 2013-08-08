class SerialMeasurementGroup < ActiveRecord::Base
  belongs_to :meego_test_case
  attr_accessible :long_json, :name
end
