class SiteController < ApplicationController
  skip_before_action :html_redirect, only: [:feedback]
  before_action :admin_required, only: [:feedback]

  def home
  end

  def information
  end
  
  def login
    saved = false

    if request.post?
      @user = User.find_by(username: params[:username]).try(:authenticate, params[:password])
      
      if saved = @user.present?
        set_current_user_cookie @user.id
      end

      respond_to do |format|
        format.json do
          if saved
            render json: { id: @user.id, api_key: user_api_key(@user) }
          else
            render json: { errors: { password: ['incorrect'] } }, status: :unprocessable_entity
          end
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: { }, status: :unprocessable_entity
        end
      end
    end
  end

  def app_login
    begin
      if params[:token].present?
        token = @@verifier.verify(params[:token])
        if token[:user_id].present?
          set_current_user_cookie token[:user_id]
        end
      end
      if token[:path].present?
        redirect_to "//#{ENV['V3_APP_URL']}#{token[:path]}", status: 307
        return
      end
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end
    redirect_to "//#{ENV['V3_APP_URL']}/", status: 307
  end
  
  def logout
    if request.post?
      reset_session
      delete_current_user_cookie
    end
    
    respond_to do |format|
      format.html do
        redirect_to site_login_url
      end
      format.json do
        render json: {}
      end
    end
  end

  def testerror
    raise 'Test!'
  end

  def feedback
    @users = User.all.order('updated_at DESC').limit(1000)
    @locations = Location.where(user_id: @users.pluck(:id)).select(:id, :user_id).group_by{|i| i.user_id}
    respond_to do |format|
      format.html do
        render layout: nil
      end
    end
  end
end
