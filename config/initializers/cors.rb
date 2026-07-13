frontend_origin = ENV.fetch("FRONTEND_ORIGIN") do
  next "http://localhost:3000" if Rails.env.local?

  raise KeyError, "key not found: FRONTEND_ORIGIN"
end
Rails.application.config.x.frontend_origin = frontend_origin

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins frontend_origin

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head]
  end
end
