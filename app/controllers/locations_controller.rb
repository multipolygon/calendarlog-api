class LocationsController < ApplicationController
  before_action :login_required, except: [:index, :show] # TODO
  before_action :find, except: [:index, :new, :create]
  before_action :admin_required, only: [:userlogin]

  def index
    @locations = Location.
                   not_deleted.
                   where('last_record_at IS NOT NULL').
                   order('RANDOM()').
                   limit(1000)
    
    @show_totals = true
    
    @locations = if params[:_all].present?
                   @show_totals = false
                   @locations
                   
                 elsif params[:_recent].present?
                   @show_totals = false
                   @locations.
                     where('updated_at > ?', 2.days.ago)
                   
                 else
                   @locations.
                     where('last_record_at > ?', 1.month.ago).
                     where('created_at < ?', 2.days.ago). ## confuse spammers by hiding brand new locations
                     where("title IS NOT NULL AND title != ''")
                 end

    respond_to { |format|
      format.html
      format.json
      format.text { render plain: @locations.pluck(:id).map{|id| "%08d" % id}.join("\n") }
    }
  end

  def new
    @location = Location.new
    @location.region = ''
    @location.country = 'Australia'
  end

  def create
    @location = Location.new location_params
    @location.user = current_user

    saved = @location.save

    respond_to do |format|
      format.html do
        if saved
          flash[:success] = 'Saved'
          redirect_to location_url(@location)
        else
          render 'new'
        end
      end
      format.json do
        if saved
          render json: { id: @location.id }
        else
          render json: { errors: @location.errors }, status: :unprocessable_entity
        end
      end
    end    
  end

  def show
    if request.host.starts_with? 'cache'
      expires_in 24.hours, public: true
      fresh_when etag: @location, last_modified: @location.updated_at, public: true
    end
    
    @current_year = params[:year].present? ? params[:year].to_i : Time.now.localtime.year
    @current_month = params[:month].present? ? params[:month].to_i : Time.now.localtime.month
    @current_day = params[:day].present? ? params[:day].to_i : Time.now.localtime.day
    @current_date = DateTime.new(@current_year, @current_month, @current_day).to_date

    respond_to { |format|
      format.html {
        @records_hash = @location.records_hash @current_year
      }
      format.json {
        if params[:download].present?
          response.header['Content-Disposition'] = "attachment; filename=\"#{@location.title.parameterize}-#{Time.now.localtime.strftime('%Y-%m-%d')}.json\""
        end
      }
      format.csv {
        require 'csv'
        CSV.generate { |rows|
          @location.precipitation.each_pair do |year, months|
            months.each_pair do |month, days|
              days.each_pair do |day, val|
                begin
                  rows << [Date.new(year.to_i, month.to_i, day.to_i), val]
                rescue Date::Error
                end
              end
            end
          end
        }.tap { |csv|
          send_data csv, filename: "#{@location.title.parameterize}-#{Time.now.localtime.strftime('%Y-%m-%d')}.csv", type: "text/csv", disposition: "attachment"
        }
      }
      format.xml
    }
  end

  def edit
  end

  def update
    if current_user.can_edit_location?(@location) || current_user.admin
      @location.assign_attributes location_params

      saved = @location.save

      respond_to do |format|
        format.html do
          if saved
            flash[:success] = 'Saved'
            redirect_to location_url(@location)
          else
            render 'edit'
          end
        end
        format.json do
          if saved
            render json: { id: @location.id }
          else
            render json: { errors: @location.errors }, status: :unprocessable_entity
          end
        end
      end    
    end
  end

  def record
    unless current_user.can_edit_location? @location
      render head: 401
      return
    end

    date = Date.parse(record_params[:date])
    year = date.year.to_s
    month = date.month.to_s
    day = date.day.to_s

    [:precipitation, :temperature_min, :temperature_max].each do |prop|
      if record_params.has_key? prop
        if record_params[prop].present?
          @location.public_send("#{prop}=", {}) if @location.public_send(prop).nil?
          @location.public_send(prop)[year] = {} if @location.public_send(prop)[year].nil?
          @location.public_send(prop)[year][month] = {} if @location.public_send(prop)[year][month].nil?
          @location.public_send(prop)[year][month][day] = record_params[prop].to_f
        else
          @location.public_send(prop).try(:[], year).try(:[], month).try(:delete, day)
          @location.public_send(prop)[year].delete(month) if @location.public_send(prop).try(:[], year).try(:[], month).try(:empty?)
          @location.public_send(prop).delete(year) if @location.public_send(prop).try(:[], year).try(:empty?)
        end
      end
    end

    year_max = @location.precipitation.try(:keys).try(:sort).try(:last)
    month_max = @location.precipitation[year_max].try(:keys).try(:sort).try(:last) if year_max
    day_max = @location.precipitation[month_max].try(:keys).try(:sort).try(:last) if month_max

    @location.last_record_at = Date.new(year_max, month_max, day_max) rescue nil

    if @location.save(validate: false)
      respond_to do |format|
        format.html do
          render head: :ok
        end
        format.json do
          render json: { success: true }, status: :ok
        end
      end

    else ## not saved
      respond_to do |format|
        format.html do
          render head: :unprocessable_entity
        end
        format.json do
          render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def userlogin
    set_current_user_cookie @location.user.id
    redirect_to location_url(@location)
  end

  def destroy
    if current_user.can_edit_location?(@location) || current_user.admin
      @location.update_column :deleted_at, Time.now

      respond_to do |format|
        format.html do
          redirect_to user_url
        end
        format.json do
          render json: {}
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to location_url(@location)
        end
        format.json do
          render json: {}, status: :unprocessable_entity
        end
      end
    end
  end

  def restore
    if current_user.can_edit_location?(@location) || current_user.admin
      @location.deleted_at = nil

      if @location.save
        flash[:success] = "Location \"#{@location.title}\" restored."
      else
        flash[:error] = "Location could not be restored!"
      end

      redirect_to location_url(@location)
    end
  end

  private

  def find
    if params[:old_id].present?
      @location = Location.find_by(old_id: params[:old_id])
    else
      @location = Location.find(params[:id])
    end
  end

  def location_params
    params.require(:location).permit(:title, :street_address, :town_suburb, :post_code, :region, :country, :latitude, :longitude, :i_agree_to_creative_commons)
  end

  def record_params
    @record_params ||= params.require(:record).permit(:date, :precipitation, :temperature_min, :temperature_max)
  end
end
