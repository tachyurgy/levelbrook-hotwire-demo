# Idempotent demo-data builder for the Levelbrook Workspace. Called from
# db/seeds.rb and from the board "reset" action.
module Seeds
  module_function

  MEMBERS = [
    { name: "Ada Okafor",    role: "Staff Engineer",   color: "indigo" },
    { name: "Bjorn Hayes",   role: "Product Designer", color: "violet" },
    { name: "Priya Nandi",   role: "Backend Engineer", color: "emerald" },
    { name: "Theo Marsh",    role: "Frontend Engineer", color: "amber" },
    { name: "Lena Castro",   role: "Eng Manager",      color: "rose" },
    { name: "Sam Whitfield", role: "QA Engineer",      color: "sky" }
  ].freeze

  COLUMNS = [
    { name: "To Do",       wip_limit: nil },
    { name: "In Progress", wip_limit: 4 },
    { name: "In Review",   wip_limit: 3 },
    { name: "Done",        wip_limit: nil }
  ].freeze

  def seed_all!
    members = ensure_members
    ensure_channels(members)
    seed_project!("Platform", "LB", "platform", members, board_a)
    seed_project!("Mobile App", "MOB", "mobile", members, board_b)
  end

  def reset_project!(project)
    project.columns.destroy_all
    project.update!(issues_seq: 0)
    members = Member.order(:id).to_a
    seed_project!(project.name, project.key, project.slug, members, project.slug == "mobile" ? board_b : board_a, project)
  end

  # --- builders ---------------------------------------------------------

  def ensure_members
    MEMBERS.map do |attrs|
      Member.find_or_create_by!(name: attrs[:name]) { |m| m.role = attrs[:role]; m.color = attrs[:color] }
    end
  end

  def ensure_channels(members)
    [
      [ "general",      "Company-wide announcements and watercooler." ],
      [ "engineering",  "Deploys, incidents, and architecture chatter." ],
      [ "design",       "Mocks, critique, and design-system updates." ]
    ].each do |name, topic|
      ch = Channel.find_or_create_by!(slug: name) { |c| c.name = name; c.topic = topic }
      if ch.messages.empty?
        seed_messages(ch, members)
      end
    end
  end

  def seed_messages(channel, members)
    scripts = {
      "general" => [
        [ 0, "Morning all — board grooming at 10, then we lock the sprint." ],
        [ 4, "Reminder: the workspace demo goes out to the team today." ],
        [ 1, "Coffee machine on 3 is fixed 🎉 (kept the emoji, sue me)." ]
      ],
      "engineering" => [
        [ 2, "Shipping the morph-based board sync — drag in one tab updates everywhere." ],
        [ 0, "Nice. Did we keep SortableJS off the morphed nodes so it doesn't fight?" ],
        [ 2, "Yep, drag state is DOM-resident. Morph only touches moved cards." ],
        [ 3, "Pulled the latest — the ⌘K palette is genuinely fast." ]
      ],
      "design" => [
        [ 1, "New issue-card spec: key, label chip, priority icon, points, avatar." ],
        [ 4, "Love it. Keep the one accent — no gradients." ]
      ]
    }
    (scripts[channel.slug] || []).each do |member_index, body|
      channel.messages.create!(member: members[member_index % members.size], body: body)
    end
  end

  def seed_project!(name, key, slug, members, issues, project = nil)
    project ||= Project.find_or_initialize_by(slug: slug)
    project.assign_attributes(name: name, key: key, description: "#{name} delivery board.", issues_seq: 0)
    project.save!
    # Idempotent: rebuild the board from scratch each time.
    project.columns.destroy_all

    columns = COLUMNS.each_with_index.map do |col, i|
      project.columns.create!(name: col[:name], position: i, wip_limit: col[:wip_limit])
    end

    issues.each do |col_index, list|
      column = columns[col_index]
      list.each_with_index do |attrs, pos|
        column.issues.create!(
          title: attrs[:title],
          description: attrs[:description],
          label: attrs[:label],
          priority: attrs[:priority],
          points: attrs[:points],
          position: pos,
          assignee: attrs[:assignee] ? members[attrs[:assignee]] : nil
        )
      end
    end

    # A couple of seeded comments on the first issue for the detail demo.
    first_issue = project.issues.order(:id).first
    if first_issue && first_issue.comments.empty?
      first_issue.comments.create!(member: members[4], body: "Can we add a loading state while the frame fetches?")
      first_issue.comments.create!(member: members[0], body: "Already in — the modal shows a skeleton on lazy load.")
    end

    project
  end

  # --- board content ----------------------------------------------------

  def board_a
    {
      0 => [
        { title: "Add WIP-limit enforcement to columns", description: "Reject over-limit drops server-side and snap the card back with a streamed toast.", label: "feature", priority: "high", points: 5, assignee: 2 },
        { title: "Investigate flaky cable reconnect", description: "Presence roster occasionally double-counts a tab on reconnect.", label: "bug", priority: "medium", points: 3, assignee: 5 },
        { title: "Document the morph-vs-append decision", description: "Write up when we use broadcasts_refreshes vs broadcast_append_to.", label: "chore", priority: "low", points: 2, assignee: nil }
      ],
      1 => [
        { title: "SortableJS drag + broadcast morph sync", description: "Drag a card in one window; it moves in every connected window via a single broadcasts_refreshes morph.", label: "feature", priority: "urgent", points: 8, assignee: 0 },
        { title: "Lazy-loaded issue detail modal", description: "Click a card to open a Turbo Frame modal with inline-editable fields and a comment thread.", label: "feature", priority: "high", points: 5, assignee: 3 }
      ],
      2 => [
        { title: "Debounced live search frame", description: "Type-ahead filtering with shareable URLs and no full reload.", label: "feature", priority: "medium", points: 3, assignee: 2 },
        { title: "Persistent media player bar", description: "data-turbo-permanent player that keeps playing across all navigations with a smooth fade.", label: "feature", priority: "medium", points: 5, assignee: 1 }
      ],
      3 => [
        { title: "⌘K command palette", description: "Global palette with server-rendered, keyboard-navigated results.", label: "feature", priority: "high", points: 5, assignee: 0 },
        { title: "Toast notification side-channel", description: "Stream-appended, auto-dismissing toasts driven from anywhere.", label: "feature", priority: "low", points: 2, assignee: 3 },
        { title: "View Transitions between views", description: "Animate cross-page navigations with the View Transitions API.", label: "design", priority: "low", points: 2, assignee: 1 }
      ]
    }
  end

  def board_b
    {
      0 => [
        { title: "Offline message queue", description: "Buffer chat sends while the socket is down, flush on reconnect.", label: "feature", priority: "high", points: 8, assignee: 3 },
        { title: "Crash on cold start (Android 13)", description: "Null channel slug during deep-link boot.", label: "bug", priority: "urgent", points: 5, assignee: 5 }
      ],
      1 => [
        { title: "Hotwire Native path configuration", description: "Wire bridge components so the web app gets a native nav bar.", label: "feature", priority: "medium", points: 5, assignee: 2 }
      ],
      2 => [
        { title: "Polish the typing indicator", description: "Debounce and pluralize 'X and Y are typing…'.", label: "design", priority: "low", points: 2, assignee: 1 }
      ],
      3 => [
        { title: "Optimistic like on activity items", description: "Bump instantly on the actor's client; reconcile via morph.", label: "feature", priority: "medium", points: 3, assignee: 0 }
      ]
    }
  end
end
