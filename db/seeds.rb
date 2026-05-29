# Seeds for the Levelbrook Hotwire Showcase. Idempotent: safe to re-run.
Seeds.seed_all!   # workspace + cadence (members, projects, issues, channels)
Ballot.seed!      # live polls & Q&A rooms
Pulse.seed!       # ops dashboard services + incidents
Spindle.seed!     # albums + tracks

puts "Members:  #{Member.count}"
puts "Projects: #{Project.count} (#{Project.pluck(:key).join(', ')})"
puts "Issues:   #{Issue.count}"
puts "Channels: #{Channel.count}"
puts "Messages: #{Message.count}"
puts "Ballot:   #{Ballot::Room.count} rooms, #{Ballot::Poll.count} polls"
puts "Pulse:    #{Pulse::Service.count} services, #{Pulse::Incident.count} incidents"
puts "Spindle:  #{Spindle::Album.count} albums, #{Spindle::Track.count} tracks"
