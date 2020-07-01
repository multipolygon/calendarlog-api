json.(@location,
      :id,
      :created_at,
      :updated_at,
      :last_record_at,
      :title,
      :street_address,
      :town_suburb,
      :region,
      :country,
      :latitude,
      :longitude,
      :precipitation,
     )

json.temperatureMin @location.temperature_min
json.temperatureMax @location.temperature_max
