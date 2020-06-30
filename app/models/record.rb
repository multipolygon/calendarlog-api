class Record < ActiveRecord::Base
  belongs_to :location
  
  def date_s
    date.strftime('%Y-%m-%d')
  end
end
