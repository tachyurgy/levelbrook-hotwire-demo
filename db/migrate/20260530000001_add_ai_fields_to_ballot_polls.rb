class AddAiFieldsToBallotPolls < ActiveRecord::Migration[8.1]
  def change
    add_column :ballot_polls, :ai_generated, :boolean, default: false, null: false
    add_column :ballot_polls, :asker, :string
  end
end
