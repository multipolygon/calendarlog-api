class UserMailer < ActionMailer::Base
  def reset_password_email user, url
    @user = user
    @url = url
    mail to: user.email, subject: "Email Verification" do |format|
      format.text
    end
  end
end
