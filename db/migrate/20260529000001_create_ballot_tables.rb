class CreateBallotTables < ActiveRecord::Migration[8.1]
  def change
    create_table :ballot_rooms do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :subtitle
      t.timestamps
      t.index :slug, unique: true
    end

    create_table :ballot_polls do |t|
      t.references :room, null: false, foreign_key: { to_table: :ballot_rooms }
      t.string :question, null: false
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    create_table :ballot_options do |t|
      t.references :poll, null: false, foreign_key: { to_table: :ballot_polls }
      t.string :label, null: false
      t.integer :votes_count, default: 0, null: false
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    create_table :ballot_questions do |t|
      t.references :room, null: false, foreign_key: { to_table: :ballot_rooms }
      t.text :body, null: false
      t.string :author, null: false
      t.integer :upvotes_count, default: 0, null: false
      t.timestamps
      t.index %i[room_id upvotes_count]
    end
  end
end
