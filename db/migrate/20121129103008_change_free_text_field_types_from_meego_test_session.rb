class ChangeFreeTextFieldTypesFromMeegoTestSession < ActiveRecord::Migration

  def up
    change_table :meego_test_sessions do |t|
      t.change :objective_txt, :text
      t.change :build_txt, :text
      t.change :qa_summary_txt, :text
      t.change :issue_summary_txt, :text
      t.change :environment_txt, :text
    end
  end

  def down
    change_table :meego_test_sessions do |t|
      t.change :objective_txt, :string
      t.change :build_txt, :string
      t.change :qa_summary_txt, :string
      t.change :issue_summary_txt, :string
      t.change :environment_txt, :string
    end
  end
end
