module QueryCounter
  # Counts SQL queries issued inside the block (SCHEMA/CACHE/TRANSACTION
  # statements excluded), so specs can assert against N+1 regressions
  # without depending on an extra gem.
  def count_queries(&block)
    count = 0
    counter = lambda do |_name, _started, _finished, _unique_id, payload|
      count += 1 unless %w[SCHEMA CACHE].include?(payload[:name]) || payload[:sql].match?(/\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i)
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end

RSpec.configure { |config| config.include QueryCounter }
