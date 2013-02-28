class AddHideSummaryToMeegoTestSession < ActiveRecord::Migration
  def change
    add_column :meego_test_sessions, :hide_summary, :boolean, :default => 0
  end
end
