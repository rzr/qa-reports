class AddSerialMeasurementGroupToSerialMeasurements < ActiveRecord::Migration
  def up
    add_column :serial_measurements, :serial_measurement_group_id, :integer
  end

  def down
    remove_column :serial_measurements, :serial_measurement_group_id
  end
end
