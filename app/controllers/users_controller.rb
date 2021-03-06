class UsersController < ApplicationController
  before_action :login_required, except: [:create]

  def create
    @user = User.new user_params

    if saved = @user.save
      set_current_user_cookie @user.id
    end

    respond_to do |format|
      format.json do
        if saved
          render json: { id: @user.id }
        else
          render json: { errors: @user.errors }, status: :unprocessable_entity
        end
      end
    end
  end
  
  def show
  end
  
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    
    @user.assign_attributes user_params

    saved = @user.save

    respond_to do |format|
      format.json do
        if saved
          render json: { }
        else
          render json: { errors: @user.errors }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :feedback_rating, :feedback_text, :system_message)
  end
end
