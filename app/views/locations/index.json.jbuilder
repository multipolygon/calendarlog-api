json.type 'FeatureCollection'

json.features(@locations) do |item|
  json.type 'Feature'
  json.geometry do
    json.type "Point"
    json.coordinates(
      if item.latitude.nil? || item.longitude.nil?
        [133.333, -26.974]
      else
        [item.longitude.round(3), item.latitude.round(3)]
      end
    )
  end
  json.properties do
    json.id item.id
    json.location [item.town_suburb.try(:titlecase), item.region, item.country].reject(&:blank?).compact.join(', ')
    json.updated_at item.updated_at
    json.last_record_at item.last_record_at
    if @show_totals && item.last_record_at >= 30.days.ago
      json.total_7_days item.total_7_days
      json.total_30_days item.total_30_days
    end
  end
end
