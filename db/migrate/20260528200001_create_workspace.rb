class CreateWorkspace < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.string :name, null: false
      t.string :role, null: false, default: "Engineer"
      t.string :color, null: false, default: "indigo"
      t.timestamps
    end

    create_table :projects do |t|
      t.string :name, null: false
      t.string :key, null: false         # e.g. "LB" -> issue keys LB-142
      t.string :slug, null: false
      t.text :description
      t.integer :issues_seq, null: false, default: 0
      t.timestamps
      t.index :slug, unique: true
      t.index :key, unique: true
    end

    create_table :columns do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.integer :wip_limit
      t.timestamps
      t.index [ :project_id, :position ]
    end

    create_table :issues do |t|
      t.references :column, null: false, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :members }
      t.integer :number, null: false       # per-project sequence -> KEY-number
      t.string :title, null: false
      t.text :description
      t.string :label, null: false, default: "feature"  # feature/bug/chore/design
      t.string :priority, null: false, default: "medium" # urgent/high/medium/low
      t.integer :points, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.timestamps
      t.index [ :column_id, :position ]
    end

    create_table :comments do |t|
      t.references :issue, null: false, foreign_key: true
      t.references :member, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end

    create_table :channels do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :topic
      t.timestamps
      t.index :slug, unique: true
    end

    create_table :messages do |t|
      t.references :channel, null: false, foreign_key: true
      t.references :member, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
  end
end
