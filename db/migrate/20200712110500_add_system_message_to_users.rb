class AddSystemMessageToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :system_message, :text
  end
end
