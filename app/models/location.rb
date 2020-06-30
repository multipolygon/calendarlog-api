class Location < ActiveRecord::Base
  belongs_to :user
  has_many :records, dependent: :delete_all
  
  scope :not_deleted, -> { where('deleted_at IS NULL') }
  
  REGIONS = [
    ['', 'other'],
    ['NT', 'Northern Territory'],
    ['WA', 'Western Australia'],
    ['QLD', 'Queensland'],
    ['NSW', 'New South Wales'],
    ['ACT', 'Australian Capital Territory'],
    ['SA', 'South Australia'],
    ['VIC', 'Victoria'],
    ['TAS', 'Tasmania'],
  ]
  
  validates :title, length: { maximum: 255 }, presence: true
  # validates :title, format: { with: /\A[a-zA-Z0-9_\-\.,' ]*\z/, message: "can only contain letters, numbers and hyphens" }, allow_blank: true, on: :create
  
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
  
  def years
    records.where('precipitation IS NOT NULL').select("strftime('%Y', date) as year").uniq.collect(&:year).sort
  end
  
  def records_hash y
    Hash[records.where('precipitation IS NOT NULL').where('date >= ? AND date <= ?', DateTime.new(y, 1, 1).to_date, DateTime.new(y, 12, 31).to_date).order(:date).collect{ |i| [i.date_s, i.precipitation.try(:round, 1)] }]
  end
  
  def total_7_days
    records.where('date >= ?', 7.days.ago.to_date).sum(:precipitation).try(:round)
  end
  
  def total_30_days
    records.where('date >= ?', 30.days.ago.to_date).sum(:precipitation).try(:round)
  end
  
  def total_month year, month
    t = DateTime.new(year, month, 1)
    records.where('date >= ? AND date <= ?', t.beginning_of_month.to_date, t.end_of_month.to_date).sum(:precipitation).try(:round)
  end
  
  def total_year year
    t = DateTime.new(year, 1, 1)
    records.where('date >= ? AND date <= ?', t.beginning_of_year.to_date, t.end_of_year.to_date).sum(:precipitation).try(:round)
  end
end
