class CreatePulseTables < ActiveRecord::Migration[8.1]
  def change
    create_table :pulse_services do |t|
      t.string  :name, null: false
      t.string  :slug, null: false
      t.string  :status, default: "healthy", null: false
      t.integer :latency_ms, default: 80, null: false
      t.float   :error_rate, default: 0.2, null: false
      t.integer :throughput, default: 1200, null: false
      t.text    :samples, default: "[]", null: false
      t.integer :position, default: 0, null: false
      t.timestamps
      t.index :slug, unique: true
    end

    create_table :pulse_incidents do |t|
      t.references :service, foreign_key: { to_table: :pulse_services }
      t.string   :title, null: false
      t.string   :severity, default: "sev3", null: false
      t.string   :status, default: "open", null: false
      t.datetime :started_at, null: false
      t.timestamps
    end
  end
end
