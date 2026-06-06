# Deterministic seed for the e2e run. Wipes the mutable demo data and rebuilds
# it from the canonical seeder so every Playwright run starts from a known state
# regardless of what previous runs (drags, comments) left behind.
# Invoked by the Playwright webServer command via `bin/rails runner`.
Comment.delete_all

Seeds.seed_all!   # members, both project boards, seed comments

puts "[e2e] seed complete: #{Project.count} boards, #{Issue.count} issues, " \
     "#{Member.count} members"
