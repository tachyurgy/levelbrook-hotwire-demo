class AddReactionsToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :reactions, :text, default: "{}", null: false
  end
end
