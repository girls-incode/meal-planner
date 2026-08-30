# Subscribes to the "pantry.updated" domain event published by the
# PantryItems service objects. Deliberately minimal — logging only for now
# — but is the seam where future cache invalidation or async side effects
# would attach, without introducing a queue/broker for this prototype.
class PantrySubscriber
  def self.call(_name, _started, _finished, _unique_id, payload)
    Rails.logger.info(
      "[pantry.updated] pantry_id=#{payload[:pantry_id]} action=#{payload[:action]} " \
      "ingredient_id=#{payload[:ingredient_id]}"
    )
  end
end
