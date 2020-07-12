json.(current_user, :id, :created_at, :updated_at, :username, :email, :verified_email, :system_message, :feedback_rating, :feedback_text) if current_user

json.email_verified current_user.email_verified?
json.email_sent !current_user.verification_token.nil?

json.api_key current_user_api_key

json.locations(current_user.try(:locations).try(:not_deleted) || []) do |item|
  json.id item.id
  json.title item.title
  json.location [item.town_suburb.try(:titlecase), item.region].reject(&:blank?).compact.join(', ')
  json.total_7_days item.total_7_days
  json.total_30_days item.total_30_days
end

