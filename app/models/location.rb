class Location < ActiveRecord::Base
  belongs_to :user

  scope :not_deleted, -> { where('deleted_at IS NULL') }

  validates :title, length: { maximum: 255 }, presence: true

  validates :street_address, length: { maximum: 255 }

  validates :town_suburb, length: { maximum: 255 }, presence: true

  validates :post_code, length: { maximum: 255 }

  validates :region, length: { maximum: 255 }, presence: true

  validates :country, length: { maximum: 255 }, presence: true

  validates :latitude, allow_nil: true, numericality: {
              greater_than_or_equal_to: -90,
              less_than_or_equal_to: 90,
              message: 'not valid',
            }

  validates :longitude, allow_nil: true, numericality: {
              greater_than_or_equal_to: -180,
              less_than_or_equal_to: 180,
              message: 'not valid',
            }

  validates_acceptance_of :i_agree_to_creative_commons, on: :create, message: 'must agree'

  def latitude
    read_attribute(:latitude).try(:round, 3)
  end

  def longitude
    read_attribute(:longitude).try(:round, 3)
  end

  def total_days days
    days.times.reduce(0) do |total, n|
      d = n.days.ago
      total + (precipitation.try(:[], d.year.to_s).try(:[], d.month.to_s).try(:[], d.day.to_s) || 0)
    end.round(2)
  end

  def total_7_days
    total_days 7
  end

  def total_30_days
    total_days 30
  end

  def get_precipitation_last_record_date
    year_max = precipitation.try(:keys).try(:sort).try(:last)
    if year_max
      month_max = precipitation[year_max].try(:keys).try(:sort).try(:last)
      if month_max
        day_max = precipitation[year_max][month_max].try(:keys).try(:sort).try(:last)
        if day_max
          begin
            return Date.new(year_max.to_i, month_max.to_i, day_max.to_i)
          rescue Date::Error
          end
        end
      end
    end
    return nil
  end
end
