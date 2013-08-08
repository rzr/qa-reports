class SerialMeasurementGroup < ActiveRecord::Base
  belongs_to :meego_test_case
  has_many   :serial_measurements, :dependent => :destroy

  attr_accessible :long_json, :name

  def is_serial?
    true
  end
end
