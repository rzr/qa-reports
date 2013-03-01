class AddHideMetricsToMeegoTestSession < ActiveRecord::Migration
  def change
    add_column :meego_test_sessions, :hide_metrics, :boolean, :default => 0
  end
end
