class AddTcIdToMeegoTestCase < ActiveRecord::Migration
  def change
    add_column :meego_test_cases, :tc_id, :string
  end
end
