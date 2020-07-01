class AddJsonFieldsToLocations < ActiveRecord::Migration[6.0]
  def change
    add_column :locations, :precipitation, :jsonb
    add_column :locations, :temperature_min, :jsonb
    add_column :locations, :temperature_max, :jsonb
  end
end
