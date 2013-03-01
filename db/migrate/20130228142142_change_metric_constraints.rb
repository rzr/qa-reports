class ChangeMetricConstraints < ActiveRecord::Migration
  def up
    change_column :metrics, :group_name, :string, :null => false
    change_column :metrics, :name, :string, :null => false
    change_column :metrics, :value, :float, :null => false
  end
end
