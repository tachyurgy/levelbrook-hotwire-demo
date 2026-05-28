class CreateStories < ActiveRecord::Migration[8.1]
  def change
    create_table :stories do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :blurb
      t.string :tagline

      t.timestamps
    end

    add_index :stories, :slug, unique: true
  end
end
