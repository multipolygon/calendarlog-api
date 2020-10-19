countries = JSON.parse(File.read(File.join(Rails.root, 'lib', 'countries-cities.json')))

json.type 'FeatureCollection'

json.features(@locations) do |item|
  json.type 'Feature'
  json.geometry do
    json.type "Point"
    json.coordinates(
      if item.latitude.nil? || item.longitude.nil?
        if item.country.present? && countries.include?(item.country.capitalize)
          country = countries[item.country.capitalize]
          if item.town_suburb.present? && country['ct'].include?(item.town_suburb.capitalize)
            country['ct'][item.town_suburb.capitalize]
          else
            country['co']
          end
        else
          [0.0, 0.0]
        end
      else
        [item.longitude.round(3), item.latitude.round(3)]
      end
    )
  end
  json.properties do
    json.id item.id
    json.location(
      [
        item.town_suburb.try(:capitalize),
        item.country.try(:capitalize)
      ].reject(&:blank?).compact.join(', ')
    )
    json.updated_at item.updated_at
    json.last_record_at item.last_record_at
    if @show_totals && item.last_record_at >= 30.days.ago
      json.total_7_days item.total_7_days
      json.total_30_days item.total_30_days
    end
  end
end
