# The always-on heartbeat of the Pulse dashboard. Each run takes exactly ONE
# sample of every service, broadcasts the targeted Turbo Stream updates, writes a
# heartbeat, then re-enqueues itself `wait: Pulse::TICK` later. It frees its
# worker thread between ticks (no sleep loop), and the generation guard means a
# stale chain (e.g. left over from before a deploy) stops itself the moment a
# newer chain has taken over — so the board never runs two tic
# chains at once. Kicked off lazily by Pulse.ensure_live! on each dashboard load.
class Pulse::TickJob < ApplicationJob
  queue_as :default

  def perform(generation)
    return unless generation == Pulse.current_generation

    Pulse.tick!
    Rails.cache.write(Pulse::BEAT_KEY, Pulse.now)
    self.class.set(wait: Pulse::TICK.seconds).perform_later(generation)
  end
end
