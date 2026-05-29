class CreateGridTables < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_sheets do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :unit, default: "$", null: false
      t.timestamps
      t.index :slug, unique: true
    end

    create_table :grid_rows do |t|
      t.references :sheet, null: false, foreign_key: { to_table: :grid_sheets }
      t.string  :label, null: false
      t.string  :category, default: "—", null: false
      t.integer :qty, default: 1, null: false
      t.integer :unit_price, default: 0, null: false
      t.integer :position, default: 0, null: false
      t.timestamps
    end
  end
end
