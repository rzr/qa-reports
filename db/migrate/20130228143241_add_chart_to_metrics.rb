class AddChartToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :chart, :boolean, :default => false
  end
end
