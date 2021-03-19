class UserMailer < ActionMailer::Base
  def reset_password_email user, url
    @user = user
    @url = url
    mail to: user.email, subject: "Rainfall Record user account for #{@user.username}" do |format|
      format.text
    end
  end
end
