# Seeds for the Levelbrook Hotwire demos. Idempotent: safe to re-run.

# --- Demo 1: Collaborative Kanban -------------------------------------------
BoardSeeder.reset!
puts "Seeded board: #{Board.first.name} (#{Board.first.columns.count} columns, #{Card.count} cards)"

# --- Demo 2: Choose-Your-Path Story Engine ----------------------------------
# A complete 13-scene branching narrative. Scenes are keyed by string; choices
# point at a target scene key. Endings have no choices.
StorySeeder.reset!
story = Story.find_by(slug: "the-last-signal")
puts "Seeded story: #{story.title} (#{story.scenes.count} scenes, #{story.choices.count} choices)"
