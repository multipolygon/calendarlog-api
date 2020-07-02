class PasswordResetsController < ApplicationController
  require 'securerandom'
  skip_before_action :html_redirect, only: [:edit]

  def new
  end

  def create
    @user = if current_user.present?
      current_user
    else
      User.find_by('email' => params[:email])
    end

    if @user.present?
      @user.verification_token = SecureRandom.base64(16)
      @user.save(validate: false)
      signature = message_verifier.generate({ email: @user.email })
      verification_url = edit_password_reset_url(@user.id, signature: signature)
      UserMailer.reset_password_email(@user, verification_url).deliver
    end

    respond_to do |format|
      format.json do
        render json: {}
      end
    end
  end

  def edit
    @user = User.find(params[:id])
    begin
      data =  message_verifier.verify(params[:signature])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to site_login_url
    else
      @user.verification_token = ""
      if data.include?(:email) && data[:email] == @user.email && @user.verified_email != @user.email
        @user.verified_email = @user.email
      end
      @user.save(validate: false)
      set_current_user_cookie @user.id
      if ENV['V3_APP_URL'].present?
        redirect_to "https://#{ENV['V3_APP_URL']}/user"
      else
        redirect_to user_url
      end
    end
  end

  private

  def message_verifier
    @verifier ||= ActiveSupport::MessageVerifier.new('928y3hjasdf' + @user.verification_token + ENV["SECRET_KEY_BASE"])
  end
end
