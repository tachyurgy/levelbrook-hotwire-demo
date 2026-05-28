class CreateChoices < ActiveRecord::Migration[8.1]
  def change
    create_table :choices do |t|
      t.references :scene, null: false, foreign_key: true
      t.string :target_key, null: false
      t.string :label, null: false
      t.integer :position, null: false, default: 0
      t.integer :picks_count, null: false, default: 0

      t.timestamps
    end

    add_index :choices, [ :scene_id, :position ]
  end
end
