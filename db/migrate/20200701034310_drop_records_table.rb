class DropRecordsTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :records
  end

  def down
  end
end
