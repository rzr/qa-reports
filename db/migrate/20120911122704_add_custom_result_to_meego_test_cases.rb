class AddCustomResultToMeegoTestCases < ActiveRecord::Migration
  def change
    add_column :meego_test_cases, :custom_result_id, :integer
  end
end
