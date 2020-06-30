json.(@location, :id, :created_at, :updated_at, :title, :street_address, :town_suburb, :region, :country)

json.latitude @location.latitude.try(:round, 3)
json.longitude @location.longitude.try(:round, 3)

[:precipitation, :temperature_min, :temperature_max].each do |src|
  years = Hash.new{ |h,k| h[k] = Hash.new{ |h,k| h[k] = Hash.new{ |h,k| h[k] = {} } } }

  json.set!(
    src.to_s.camelcase(:lower),
    @location
      .records
      .where("#{src} IS NOT NULL")
      .order('date DESC')
      .pluck(:date, src)
      .reduce(years) { |obj, item|
      date, measurement = item
      obj[date.year][date.month][date.day] = measurement
      obj
    }
  )
end
