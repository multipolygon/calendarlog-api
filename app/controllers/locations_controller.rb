class LocationsController < ApplicationController
  # before_action :login_required
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

    expires_in 24.hours, public: true

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
          @location.records.order('date DESC').pluck(:date, :precipitation).each { |i|
            rows << i
          }
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

    record = Record.new record_params
    record.location = @location

    if record.valid?
      @location.records.where(date: record.date).delete_all
    end

    if record.save
      @location.last_record_at = record.date if not(record.precipitation.nil?) && (@location.last_record_at.nil? || record.date > @location.last_record_at)
      @location.updated_at = Time.now
      @location.save(validate: false)
      
      respond_to do |format|
        format.html do
          render head: :ok
        end
        format.json do
          render json: { success: true }, status: :ok
        end
        format.js do
          js = ''
          next_day = record.date + 1.day
          if params[:current_year].present? && params[:current_year].to_i != next_day.year
            js << "window.location.replace('#{location_url(@location, year: next_day.year, month: next_day.month, day: next_day.day)}');"
          else
            js << "$('##{record.date.strftime('%Y-%m-%d')}').text('#{record.precipitation.try(:round, 1).to_s.gsub('.0', '')}');"
            js << "$('##{record.date.strftime('total-%Y-%m')}').text('#{@location.total_month(record.date.year, record.date.month)}');"
            js << "$('.#{record.date.strftime('total-year-%Y')}').text('#{@location.total_year(record.date.year)}');"
            if next_day
              js << "selectDate(#{next_day.year}, #{next_day.month}, #{next_day.day}, '');"
              js << "$('##{next_day.strftime('%Y-%m-%d')}').addClass('active');"
            end
            js << "updateGraph();"
            js << "updateAllYearsGraph();"
          end
          render js: js
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
        format.js do
          render js: "alert('#{record.errors.full_messages.join(', ')}');"
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
    params.require(:record).permit(:date, :precipitation, :temperature_min, :temperature_max)
  end
end
