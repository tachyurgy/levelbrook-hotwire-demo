class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.references :column, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.string :assignee
      t.string :tag
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :cards, [ :column_id, :position ]
  end
end
