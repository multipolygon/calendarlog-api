class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception, unless: -> { params[:api_key].present? }
  skip_before_action :verify_authenticity_token

  helper_method :v3_app_path
  def v3_app_path
    if controller_name == 'locations'
      if params[:id].present?
        "/location?id=#{params[:id]}"
      else
        "/locations"
      end
    elsif controller_name == 'users'
      "/user"
    else
      "/"
    end
  end

  helper_method :v3_app_params
  def v3_app_params
    {
      token: verifier.generate(
        {
          user_id: logged_in? ? current_user.id : nil,
          path: v3_app_path,
        }
      )
    }.to_param
  end

  before_action :html_redirect
  def html_redirect
    if ENV['LEGACY_URL'].present? && ENV['V3_API_URL'].present? && ENV['V3_APP_URL'].present? && request.host == ENV['LEGACY_URL']
      if logged_in?
        redirect_to "#{request.protocol}#{ENV['V3_API_URL']}/app_login.json?#{v3_app_params}", status: 307
      else
        redirect_to "https://#{ENV['V3_APP_URL']}#{v3_app_path}", status: 301
      end
      return false
    end

    if request.format == 'html'
      render plain: 'Not found', status: 404
      return false
    end
    
    true
  end

  LEGACY_USER_COOKIE = :current_user_id
  CURRENT_USER_COOKIE = :current_user_id_v2
 
  @@verifier = ActiveSupport::MessageVerifier.new ENV["SECRET_KEY_BASE"], digest: 'SHA256'

  helper_method :verifier
  def verifier
    @@verifier
  end

  def user_api_key user
    @@verifier.generate "#{user.id}-#{Digest::SHA256.hexdigest(user.password_digest)}"
  end

  helper_method :current_user_api_key
  def current_user_api_key
    if current_user
      user_api_key current_user
    end
  end

  def find_user_by_api_key(api_key)
    user_id, key = @@verifier.verify(api_key).split('-', 2)
    user = User.find(user_id)
    key == Digest::SHA256.hexdigest(user.password_digest) ? user : nil
  end

  helper_method :current_user
  def current_user
    @current_user ||= if cookies.signed.permanent[CURRENT_USER_COOKIE].present?
                        User.find_by_id cookies.signed.permanent[CURRENT_USER_COOKIE]
                      elsif cookies.signed.permanent[LEGACY_USER_COOKIE].present?
                        user = User.find_by_id cookies.signed.permanent[LEGACY_USER_COOKIE]
                        set_current_user_cookie(user.id) if user
                        user
                      elsif session[:current_user_id].present?
                        user = User.find_by_id session[:current_user_id]
                        set_current_user_cookie(user.id) if user
                        user
                      elsif params[:api_key].present?
                        find_user_by_api_key(params[:api_key])
                      elsif request.headers['Authorization'].present?
                        type, key = request.headers['Authorization'].split(' ', 2)
                        find_user_by_api_key(key)
                      else
                        nil
                      end
  end

  helper_method :logged_in?
  def logged_in?
    current_user.present?
  end

  def not_authorised
    respond_to do |format|
      format.html do
        redirect_to site_login_url
      end
      format.json do
        render json: {}, status: 403
      end
      format.csv do
        render text: 'Not logged in', status: 403
      end
    end
    false
  end

  def login_required
    if logged_in?
      true
    else
      not_authorised
    end
  end

  def admin_required
    if logged_in? && current_user.admin
      true
    else
      not_authorised
    end
  end

    
  def current_user_cookie_options
    {
      domain: ['.' + URI.parse(request.original_url).host.split('.')[-2..-1].join('.')],
      secure: Rails.env.production?,
      httponly: false,
      expires: 10.years.from_now,
    }
  end

  def set_current_user_cookie user_id
    cookies.signed.permanent[CURRENT_USER_COOKIE] = {
      value: user_id,
      **current_user_cookie_options
    }
  end

  def delete_current_user_cookie
    cookies.delete CURRENT_USER_COOKIE, current_user_cookie_options
    cookies.delete LEGACY_USER_COOKIE
  end
end
