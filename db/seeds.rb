# Seeds for the Levelbrook Hotwire Showcase. Idempotent: safe to re-run.
Seeds.seed_all!   # workspace + cadence (members, projects, issues, channels)
Ballot.seed!      # live polls & Q&A rooms

puts "Members:  #{Member.count}"
puts "Projects: #{Project.count} (#{Project.pluck(:key).join(', ')})"
puts "Issues:   #{Issue.count}"
puts "Channels: #{Channel.count}"
puts "Messages: #{Message.count}"
puts "Ballot:   #{Ballot::Room.count} rooms, #{Ballot::Poll.count} polls"
