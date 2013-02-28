class CreateMetrics < ActiveRecord::Migration
  def change
    create_table :metrics do |t|
      t.integer :meego_test_session_id
      t.string :group_name
      t.string :name
      t.string :unit
      t.float :value
    end
  end
end
