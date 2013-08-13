class CreateSerialMeasurementGroups < ActiveRecord::Migration
  def change
    create_table :serial_measurement_groups do |t|
      t.string :name
      t.text :long_json
      t.references :meego_test_case
    end
    add_index :serial_measurement_groups, :meego_test_case_id
  end
end
