# Seeds for the Levelbrook Workspace. Idempotent: safe to re-run.
Seeds.seed_all!

puts "Members:  #{Member.count}"
puts "Projects: #{Project.count} (#{Project.pluck(:key).join(', ')})"
puts "Issues:   #{Issue.count}"
puts "Channels: #{Channel.count}"
puts "Messages: #{Message.count}"
