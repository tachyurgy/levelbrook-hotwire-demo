# Ballot — live polls & audience Q&A. Namespacing the models under Ballot keeps
# this app's tables (ballot_*) and classes cleanly separated from the rest of
# the showcase. table_name_prefix wires Room -> ballot_rooms, etc.
module Ballot
  def self.table_name_prefix = "ballot_"

  # Idempotent demo data: two live rooms, each with polls + seeded questions.
  def self.seed!
    return if Room.exists?

    standup = Room.create!(name: "Sprint Retro — Live", slug: "sprint-retro",
      subtitle: "Vote and ask anything. Tallies update for everyone, instantly.")
    standup.polls.create!(question: "How did this sprint feel?", position: 0).options.create!(
      [ { label: "🔥 Best one yet", position: 0, votes_count: 7 },
        { label: "🙂 Solid", position: 1, votes_count: 12 },
        { label: "😐 Mixed", position: 2, votes_count: 5 },
        { label: "🫠 Rough", position: 3, votes_count: 2 } ])
    standup.polls.create!(question: "What should we invest in next?", position: 1).options.create!(
      [ { label: "Test coverage", position: 0, votes_count: 9 },
        { label: "Deploy speed", position: 1, votes_count: 6 },
        { label: "Docs", position: 2, votes_count: 3 },
        { label: "On-call tooling", position: 3, votes_count: 8 } ])
    standup.questions.create!(
      [ { author: "Priya", body: "Can we automate the release notes next sprint?", upvotes_count: 14 },
        { author: "Theo", body: "Why did the staging deploy take 20 minutes on Tuesday?", upvotes_count: 9 },
        { author: "Sam", body: "Should QA get earlier access to feature branches?", upvotes_count: 5 } ])

    allhands = Room.create!(name: "All-Hands Q&A", slug: "all-hands",
      subtitle: "Ask the room. Upvote what matters. Live.")
    allhands.polls.create!(question: "Remote, hybrid, or in-office for Q3?", position: 0).options.create!(
      [ { label: "Fully remote", position: 0, votes_count: 22 },
        { label: "Hybrid 2 days", position: 1, votes_count: 18 },
        { label: "In office", position: 2, votes_count: 4 } ])
    allhands.questions.create!(
      [ { author: "Ada", body: "What's the headcount plan for the platform team?", upvotes_count: 11 },
        { author: "Bjorn", body: "Are we revisiting the design-system roadmap?", upvotes_count: 6 } ])
  end
end
