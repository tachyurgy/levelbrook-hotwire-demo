# Tracks who is present in a chat channel. Presence is ephemeral state held in
# Rails.cache; on every change we broadcast the current roster to all subscribers.
class PresenceChannel < ApplicationCable::Channel
  def subscribed
    @slug = params[:slug]
    return reject if @slug.blank?

    stream_from stream_name
    mark_present
    broadcast_roster
  end

  def unsubscribed
    mark_absent
    broadcast_roster
  end

  def present(_data = {})
    mark_present
    broadcast_roster
  end

  private

  def stream_name = "presence:#{@slug}"

  def cache_key = "presence/#{@slug}"

  def member_name
    connection.member_name
  end

  def mark_present
    roster = current_roster
    roster[member_name] = Time.current.to_i
    Rails.cache.write(cache_key, prune(roster), expires_in: 5.minutes)
  end

  def mark_absent
    roster = current_roster
    roster.delete(member_name)
    Rails.cache.write(cache_key, roster, expires_in: 5.minutes)
  end

  def current_roster
    Rails.cache.read(cache_key) || {}
  end

  def prune(roster)
    cutoff = 2.minutes.ago.to_i
    roster.select { |_name, seen| seen >= cutoff }
  end

  def broadcast_roster
    names = prune(current_roster).keys.sort
    ActionCable.server.broadcast(stream_name, { names: names })
  end
end
