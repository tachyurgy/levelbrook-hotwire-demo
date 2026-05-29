class CreateSpindleTables < ActiveRecord::Migration[8.1]
  def change
    create_table :spindle_albums do |t|
      t.string  :title, null: false
      t.string  :slug, null: false
      t.string  :artist, null: false
      t.string  :mood
      t.string  :hue, default: "#7c3aed", null: false
      t.integer :position, default: 0, null: false
      t.timestamps
      t.index :slug, unique: true
    end

    create_table :spindle_tracks do |t|
      t.references :album, null: false, foreign_key: { to_table: :spindle_albums }
      t.string  :title, null: false
      t.integer :position, default: 0, null: false
      t.integer :bpm, default: 84, null: false
      t.string  :texture, default: "keys", null: false   # keys | pad | pluck | beat
      t.string  :roots, null: false                       # CSV of MIDI chord roots
      t.string  :duration_label, default: "3:00", null: false
      t.timestamps
    end
  end
end
