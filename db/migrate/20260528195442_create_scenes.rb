class CreateScenes < ActiveRecord::Migration[8.1]
  def change
    create_table :scenes do |t|
      t.references :story, null: false, foreign_key: true
      t.string :key, null: false
      t.string :heading, null: false
      t.text :body, null: false
      t.string :mood, null: false, default: "calm"
      t.boolean :ending, null: false, default: false
      t.string :ending_kind

      t.timestamps
    end

    add_index :scenes, [ :story_id, :key ], unique: true
  end
end
