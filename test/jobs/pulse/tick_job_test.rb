require "test_helper"

class Pulse::TickJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # The generation guard needs a cache that actually stores values (test default
  # is :null_store), so swap in a real MemoryStore for these.
  setup do
    Pulse.seed!
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown { Rails.cache = @original_cache }

  test "a tick samples, writes a heartbeat, and reschedules itself" do
    gen = Pulse.ensure_live!                 # writes generation + enqueues the first tick
    Rails.cache.delete(Pulse::BEAT_KEY)

    # perform_now runs the body once; the reschedule is left enqueued (not run),
    # so this does not recurse.
    Pulse::TickJob.perform_now(gen)

    assert Rails.cache.read(Pulse::BEAT_KEY).present?, "tick should write a heartbeat"
    assert Pulse.live?, "the board should read as live after a tick"
    assert_enqueued_with(job: Pulse::TickJob, args: [ gen ]) # chain continues
  end

  test "a stale generation stops the chain instead of rescheduling" do
    Pulse::TickJob.perform_now("stale-generation")
    assert_no_enqueued_jobs only: Pulse::TickJob
  end

  test "ensure_live! is idempotent while a heartbeat is fresh" do
    Pulse.ensure_live!
    assert_enqueued_jobs 1, only: Pulse::TickJob

    Pulse.ensure_live!   # still live -> no second chain
    assert_enqueued_jobs 1, only: Pulse::TickJob
  end
end
