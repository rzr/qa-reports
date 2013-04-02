class AddPatchesIncludedTxtToMeegoTestSession < ActiveRecord::Migration
  def change
    add_column :meego_test_sessions, :patches_included_txt, :text, :null => false
  end
end
