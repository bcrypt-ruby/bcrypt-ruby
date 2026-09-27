# frozen_string_literal: true

# Run with the desired bcrypt checkout's lib and compiled extension on $LOAD_PATH.
# Requires Ruby 3.4+, Async and IO::Event::WorkerPool.
require 'async'
require 'bcrypt'
require 'json'

workers = Integer(ENV.fetch('WORKERS', 4))
concurrency = Integer(ENV.fetch('CONCURRENCY', 8))
count = Integer(ENV.fetch('HASHES', 64))
cost = Integer(ENV.fetch('COST', 10))
runs = Integer(ENV.fetch('RUNS', 5))
raise ArgumentError, 'invalid benchmark parameters' unless workers >= 0 && concurrency > 0 && count > 0 && runs > 0 && (4..31).cover?(cost)

secret = 'async worker pool benchmark'
salt = BCrypt::Engine.generate_salt(cost)
expected = BCrypt::Engine.hash_secret(secret, salt)
clock = proc { Process.clock_gettime(Process::CLOCK_MONOTONIC) }

results = Array.new(runs) do
  pool = IO::Event::WorkerPool.new(maximum_worker_count: workers) if workers > 0
  reactor = Async::Reactor.new(worker_pool: pool)

  begin
    reactor.run do |task|
      # Warm up the extension and workers before starting the timer.
      Array.new(concurrency) do
        task.async { raise 'incorrect hash' unless BCrypt::Engine.hash_secret(secret, salt) == expected }
      end.each(&:wait)

      calls_before = pool ? pool.statistics[:call_count] : 0
      lags = []
      finished = false
      heartbeat = task.async do |timer|
        loop do
          deadline = clock.call + 0.005
          timer.sleep(0.005)
          lags << [clock.call - deadline, 0].max
          break if finished
        end
      end

      started = clock.call
      Array.new(concurrency) do |index|
        task.async do
          index.step(count - 1, concurrency) do
            raise 'incorrect hash' unless BCrypt::Engine.hash_secret(secret, salt) == expected
          end
        end
      end.each(&:wait)
      elapsed = clock.call - started
      finished = true
      heartbeat.wait

      {
        seconds: elapsed,
        hashes_per_second: count / elapsed,
        max_timer_lag_ms: lags.max * 1000,
        offloaded_calls: pool ? pool.statistics[:call_count] - calls_before : 0
      }
    end.wait
  ensure
    Fiber.set_scheduler(nil)
  end
end

median = proc { |key| results.map { |result| result.fetch(key) }.sort.then { |values| (values[(runs - 1) / 2] + values[runs / 2]) / 2.0 } }
puts JSON.pretty_generate(
  label: ENV.fetch('LABEL', 'bcrypt'),
  ruby: RUBY_DESCRIPTION,
  bcrypt_extension: $LOADED_FEATURES.find { |path| path.match?(/bcrypt_ext\.(bundle|so)$/) },
  async: Async::VERSION,
  io_event: IO::Event::VERSION,
  workers: workers, concurrency: concurrency, hashes: count, cost: cost,
  median_seconds: median.call(:seconds),
  median_hashes_per_second: median.call(:hashes_per_second),
  median_max_timer_lag_ms: median.call(:max_timer_lag_ms),
  samples: results
)
