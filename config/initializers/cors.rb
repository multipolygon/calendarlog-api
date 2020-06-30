Rails.configuration.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV['CORS_ORIGIN'].split(',')
    resource '*', headers: :any, methods: :any, credentials: true, max_age: 24.hours.to_i
  end
end
