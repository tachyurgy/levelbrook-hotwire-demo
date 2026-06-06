# Seeds for the Levelbrook Hotwire demo. Idempotent: safe to re-run.
# Only Workspace carries persistent data — Relay (AI streaming) and Forge (the
# gem playgrounds) are stateless.
Seeds.seed_all!   # workspace: members, projects, issues, comments

puts "Members:  #{Member.count}"
puts "Projects: #{Project.count} (#{Project.pluck(:key).join(', ')})"
puts "Issues:   #{Issue.count}"
puts "Comments: #{Comment.count}"
