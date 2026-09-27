# Async worker pool benchmark

`worker_pool.rb` hashes 64 passwords at cost 10 across eight Async tasks, verifies
every result, and measures elapsed time and the delay of a 5 ms heartbeat timer.
Each configuration runs five times after a warmup. Reported values are medians;
timer lag is the median of each run's maximum lag. Hash verification is included
in the timing, while salt generation, expected-hash calculation, worker creation,
and warmup are excluded.

The benchmark uses Async's `worker_pool:` scheduler option with an
`IO::Event::WorkerPool`. It calls `BCrypt::Engine.hash_secret` normally, allowing
Ruby to offload the native operation through `blocking_operation_wait`. The
pool's call counter reports how many operations were actually offloaded during
each timed batch.

## Reproduce

Use CRuby 3.4 or newer. Install the gem's development dependencies and the
benchmark dependencies, then compile the extension:

```sh
export GEM_HOME="$PWD/tmp/gems"
export GEM_PATH="$GEM_HOME"
bundle install
gem install async -v 2.46.0 --no-document
gem install io-event -v 1.22.1 --no-document
bundle exec rake compile
```

Build unmodified bcrypt from the revision used for this comparison:

```sh
mkdir -p tmp/baseline
git archive deb496eaba56077e84bd95ac9bbcca40b6d5d685 | tar -x -C tmp/baseline
(cd tmp/baseline/ext/mri && ruby extconf.rb && make)
```

Run the same script against each extension, using the same Ruby and dependencies:

```sh
for workers in 0 1 4; do
  LABEL=before WORKERS="$workers" ruby -Itmp/baseline/lib -Itmp/baseline/ext/mri benchmark/async/worker_pool.rb
  LABEL=after WORKERS="$workers" ruby -Ilib benchmark/async/worker_pool.rb
done
```

Run the benchmark with plain `ruby`: Async is an optional benchmark dependency
and is not included in the main Gemfile. `WORKERS=0` disables the pool;
`WORKERS=1` tests responsiveness with a single worker; `WORKERS=4` also allows
hashes to execute in parallel. `CONCURRENCY`, `HASHES`, `COST`, and `RUNS` override
the defaults. JSON output includes every sample, library versions, and the loaded
extension path so the compared builds can be checked.

## Results

Measured on 2026-09-28 on an Apple M4 Pro (12 CPU cores), macOS 27.0, Ruby 4.0.7
(`229531a6cf`, arm64, JIT disabled), Async 2.46.0, and io-event 1.22.1. Both
extensions used the same Ruby and compiler settings. Configurations ran
sequentially, without concurrent test runs.
The 30 individual samples are recorded in [results.csv](results.csv).

| Build | Workers | Batch time | Hashes/s | Max timer lag | Offloads/batch |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before | Disabled | 2.999 s | 21.3 | 372.45 ms | 0 |
| After | Disabled | 3.051 s | 21.0 | 379.70 ms | 0 |
| Before | 1 | 3.068 s | 20.9 | 379.79 ms | 0 |
| After | 1 | 3.084 s | 20.8 | 1.63 ms | 64 |
| Before | 4 | 3.062 s | 20.9 | 378.98 ms | 0 |
| After | 4 | 0.775 s | 82.6 | 0.77 ms | 64 |

With four workers, throughput increased **3.95 times**. With one worker,
throughput was similar but the event loop remained responsive. Merely enabling
the pool did not help the unmodified extension: no bcrypt calls reached it.
These are local batch measurements; they demonstrate parallelism and scheduler
responsiveness, not a reduction in the CPU work required for an individual hash.

## Safety and compatibility

Both native callbacks operate on frozen input strings and per-call output
buffers. They do not invoke Ruby APIs or depend on the calling thread's state.
Although the bundled crypt implementation uses `errno` internally, the Ruby
wrapper uses its return value rather than reading `errno` after the call.

The extension uses `rb_nogvl(..., RB_NOGVL_OFFLOAD_SAFE)` when available and keeps
the previous implementation on older Rubies. The regression specs verify that
both callbacks reach the scheduler, preserve their results (including failures),
and retain their inputs across mutation and garbage collection during handoff.

Validation: 44 specs passed on Ruby 4.0.7 and 3.4.4. Ruby 3.3.1 passed with the
five offload-specific specs skipped. All five offload specs fail against the
unmodified extension because its callbacks never reach the scheduler.
