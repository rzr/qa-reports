class MoveSerialMeasurementsUnderSerialMeasurementGroup < ActiveRecord::Migration
  def up
    # Create new SerialMeasurementGroup instances for all current
    # SerialMeasurements and link the measurement to those

    SerialMeasurement.all.each do |s|
      # We use the name of the measurement as group name. This will be the
      # same later on when a "group" with only one series is created.
      g = SerialMeasurementGroup.new(:name => s.name)
      g.meego_test_case_id = s.meego_test_case_id

      # Then we will create a new kind of long_json representation which
      # includes the units of the series and the interval unit. The original
      # long_json of a single measurement is not changed.
      interval_unit = s.interval_unit.nil? ? "null" : "\"#{s.interval_unit}\""
      serie     = "{\"unit\": \"#{s.unit}\", \"name\": \"#{s.name}\"}"
      long_json = "{\"series\": [#{serie}], \"interval_unit\": #{interval_unit}, \"data\": #{s.long_json}}"

      g.long_json = long_json
      g.save!

      s.serial_measurement_group = g
      s.save!
    end

    remove_column :serial_measurements, :meego_test_case_id
  end

  def down
    add_column :serial_measurements, :meego_test_case_id, :integer

    # This will ungroup the groups that have been created since adding
    # the group support so no measurements should be lost. And since no
    # other changes were made to existing measurements when putting up
    # the migration we just need to link back to meego test case.
    SerialMeasurementGroup.all.each do |g|
      g.serial_measurements.each do |s|
        s.meego_test_case_id = g.meego_test_case_id
        s.save!
      end
    end

    SerialMeasurementGroup.delete_all()
  end
end
