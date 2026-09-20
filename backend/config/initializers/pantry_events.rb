# Registered in to_prepare (rather than at top-level initializer load) so
# autoloading has finished setting up app/events before PantrySubscriber is
# referenced. In dev, to_prepare re-runs on each reload, so all subscribers
# for this event are cleared first to avoid firing the log line multiple
# times (unsubscribing by class would silently no-op, since subscribe wraps
# the class in a new internal object on every call).
Rails.application.config.to_prepare do
  ActiveSupport::Notifications.unsubscribe("pantry.updated")
  ActiveSupport::Notifications.subscribe("pantry.updated", PantrySubscriber)
end
