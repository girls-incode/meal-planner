# Registered in to_prepare (rather than at top-level initializer load) so
# autoloading has finished setting up app/events before PantrySubscriber is
# referenced. In dev, to_prepare re-runs on each reload, so the previous
# subscription is dropped first to avoid firing the log line multiple times.
Rails.application.config.to_prepare do
  ActiveSupport::Notifications.unsubscribe(PantrySubscriber) if defined?(PantrySubscriber)
  ActiveSupport::Notifications.subscribe("pantry.updated", PantrySubscriber)
end
