Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:4200", "https://majestic-haupia-a9adb2.netlify.app", "https://curious-lolly-f1d397.netlify.app" # later change to the domain of the frontend app
    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: [ :Authorization ]
  end
end
