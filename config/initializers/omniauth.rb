google_client_id = ENV.fetch("GOOGLE_CLIENT_ID") do
  next "test-client-id" if Rails.env.test?

  raise KeyError, "key not found: GOOGLE_CLIENT_ID"
end

google_client_secret = ENV.fetch("GOOGLE_CLIENT_SECRET") do
  next "test-client-secret" if Rails.env.test?

  raise KeyError, "key not found: GOOGLE_CLIENT_SECRET"
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    google_client_id,
    google_client_secret,
    scope: "email,profile",
    prompt: "select_account"
end

OmniAuth.config.logger = Rails.logger
