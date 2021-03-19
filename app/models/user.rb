class User < ActiveRecord::Base
  EMAIL_REGEXP = /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.\-]+\z/

  has_many :locations, dependent: :delete_all
  
  validates :username, presence: true
  validates :username, uniqueness: true, allow_blank: true
  validates :username, format: { with: /\A[a-z0-9]*\z/, message: "can only contain lowercase letters and numbers" }, allow_blank: true

  validates :email, presence: true
  validates :email, format: { with: EMAIL_REGEXP, message: "format is not valid" }, allow_blank: true
  
  has_secure_password

  def email_verified?
    email.try(:strip).present? && email.try(:strip) == verified_email.try(:strip)
  end
  
  def can_edit_location? location
    id == location.user_id
  end
end
