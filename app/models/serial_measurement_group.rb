class SerialMeasurementGroup < ActiveRecord::Base
  belongs_to :meego_test_case
  has_many   :serial_measurements, :dependent => :destroy

  accepts_nested_attributes_for :serial_measurements

  DELETE_BY_REPORT_ID = <<-END
    DELETE  serial_measurement_groups
    FROM    serial_measurement_groups

    INNER JOIN meego_test_cases ON
      meego_test_cases.id = serial_measurement_groups.meego_test_case_id

    WHERE meego_test_cases.meego_test_session_id = ?;
  END

  def is_serial?
    true
  end

  def self.delete_by_report_id(id)
    ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, [DELETE_BY_REPORT_ID, id]))
  end
end
