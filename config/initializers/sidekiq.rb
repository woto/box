REDIS = 'redis://redis:6379/2'

Sidekiq.configure_server do |config|
  config.redis = { url: REDIS }
end

Sidekiq.configure_client do |config|
  config.redis = { url: REDIS }
end
