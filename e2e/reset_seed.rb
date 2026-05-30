# Deterministic seed for the e2e run. Wipes the mutable demo data and rebuilds
# it from the canonical seeders so every Playwright run starts from a known
# state regardless of what previous runs (votes, messages, drags) left behind.
# Invoked by the Playwright webServer command via `bin/rails runner`.
Message.delete_all
Comment.delete_all
[ Ballot::Room, Pulse::Incident, Pulse::Service, Grid::Sheet, Spindle::Album ].each(&:destroy_all)

Seeds.seed_all!   # members, channels (+ messages), both project boards, seed comments
Ballot.seed!
Pulse.seed!
Grid.seed!
Spindle.seed!

puts "[e2e] seed complete: #{Project.count} boards, #{Issue.count} issues, " \
     "#{Channel.count} channels, #{Ballot::Room.count} ballot rooms, " \
     "#{Pulse::Service.count} services, #{Grid::Sheet.count} sheets, #{Spindle::Album.count} albums"
