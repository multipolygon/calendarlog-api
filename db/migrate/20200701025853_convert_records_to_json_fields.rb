class ConvertRecordsToJsonFields < ActiveRecord::Migration[6.0]
  def up
    Location.all.each do |location|
      puts location.id
      
      [:precipitation, :temperature_min, :temperature_max].each do |src|
        puts " > #{src}"
        
        years = Hash.new{ |h,k| h[k] = Hash.new{ |h,k| h[k] = Hash.new{ |h,k| h[k] = {} } } }

        location.public_send(
          "#{src}=",
          location.records.where("date IS NOT NULL AND #{src} IS NOT NULL").order('date DESC').pluck(:date, src).reduce(years) do |obj, item|
            date, measurement = item
            obj[date.year][date.month][date.day] = measurement
            obj
          end
        )
      end

      location.save(validate: false, touch: false)
    end
  end

  def down
  end
end
