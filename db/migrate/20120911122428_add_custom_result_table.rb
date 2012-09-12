class AddCustomResultTable < ActiveRecord::Migration

  def change
    create_table :custom_results do |t|
      t.string :name
    end
  end
end
