module ApplicationHelper
  # Turbo Stream that appends a toast to the #toasts stack. Use from any
  # controller's turbo_stream response: `toast("Saved", kind: :success)`.
  def toast_stream(title, body: nil, kind: :info)
    turbo_stream.append "toasts", partial: "shared/toast",
      locals: { id: "toast_#{SecureRandom.hex(4)}", title: title, body: body, kind: kind }
  end

  # A tiny mono caption explaining which Hotwire technique a module demonstrates.
  def technique_caption(text)
    content_tag :p, text, class: "mt-1 font-mono text-[11px] leading-relaxed text-[var(--color-ink-faint)]"
  end

  # A small pill marking how a Spindle album produces sound: live in-browser
  # synthesis (no files) vs. a real CC0 public-domain recording. This is the
  # framing that tells viewers to judge the synth tracks as engineering, not
  # as a finished record.
  def spindle_mode_badge(album, cls: "")
    if album.synth?
      label, ring, ink = "♪ Live Web Audio · no files", "ring-[var(--color-accent)]/40", "text-[var(--color-accent)]"
    else
      label, ring, ink = "CC0 · public-domain audio", "ring-emerald-500/40", "text-emerald-600"
    end
    content_tag :span, label,
      class: "inline-flex items-center rounded-full bg-[var(--color-surface)] px-2 py-0.5 font-mono text-[10px] font-medium ring-1 #{ring} #{ink} #{cls}"
  end

  def priority_icon(priority)
    color = { "urgent" => "text-[var(--color-accent)]", "high" => "text-amber-500",
              "medium" => "text-cool-500", "low" => "text-gray-300" }.fetch(priority, "text-gray-300")
    bars = { "urgent" => 3, "high" => 3, "medium" => 2, "low" => 1 }.fetch(priority, 1)
    content_tag :span, class: "inline-flex items-end gap-px #{color}", title: "#{priority.capitalize} priority" do
      safe_join((1..3).map { |i|
        content_tag :span, "", class: "w-0.5 rounded-sm #{i <= bars ? 'bg-current' : 'bg-current opacity-25'}",
          style: "height:#{2 + i * 3}px"
      })
    end
  end

  # --- Product-workspace chrome helpers ------------------------------------

  ICON_PATHS = {
    "dashboard" => '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/>',
    "board"     => '<rect x="3" y="4" width="4" height="16" rx="1"/><rect x="10" y="4" width="4" height="11" rx="1"/><rect x="17" y="4" width="4" height="14" rx="1"/>',
    "chat"      => '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>',
    "activity"  => '<path d="M22 12h-4l-3 9L9 3l-3 9H2"/>',
    "search"    => '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
    "inbox"     => '<path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>',
    "grid"      => '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M3 15h18M9 3v18M15 3v18"/>',
    "gauge"     => '<path d="M12 14 8 9"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/><circle cx="12" cy="14" r="1.5"/>',
    "poll"      => '<path d="M3 3v18h18"/><rect x="7" y="12" width="3" height="6" rx="1"/><rect x="12" y="8" width="3" height="10" rx="1"/><rect x="17" y="5" width="3" height="13" rx="1"/>',
    "music"     => '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
    "hash"      => '<path d="M4 9h16M4 15h16M10 3 8 21M16 3l-2 18"/>',
    "deploy"    => '<path d="M4 17h16M4 12h16M4 7h16"/><path d="M12 3v4"/>',
    "spark"     => '<path d="M3 12h4l3 8 4-16 3 8h4"/>',
    "grip"      => '<circle cx="9" cy="6" r="1"/><circle cx="15" cy="6" r="1"/><circle cx="9" cy="12" r="1"/><circle cx="15" cy="12" r="1"/><circle cx="9" cy="18" r="1"/><circle cx="15" cy="18" r="1"/>'
  }.freeze

  # Inline Lucide-style stroke icon. Keeps the chrome looking like a real
  # product tool rather than an emoji deck.
  def ws_icon(name, cls: "h-4 w-4")
    tag.svg(class: cls, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
            "stroke-width": "1.75", "stroke-linecap": "round", "stroke-linejoin": "round",
            "aria-hidden": "true") { raw(ICON_PATHS.fetch(name, "")) }
  end

  SECTION_TITLES = {
    "pages" => "Dashboard", "projects" => "Board", "issues" => "Board",
    "channels" => "Team room", "messages" => "Team room", "search" => "Search",
    "activities" => "Activity", "signups" => "Intake", "command" => "Command"
  }.freeze

  # The current workspace section label, for the topbar breadcrumb.
  def section_title
    SECTION_TITLES.fetch(controller_name, "Workspace")
  end

  # True when the current page belongs to one of the given controllers — used
  # to highlight the active sidebar item. The sidebar morphs on navigation, so
  # this stays in sync without JS.
  def nav_active?(*controllers)
    controllers.flatten.map(&:to_s).include?(controller_name)
  end

  # Where each showcase app opens from the gallery / switcher. Cadence has no
  # namespace (it reuses the chat routes); the rest are namespaced roots.
  def app_entry_path(app)
    case app.key
    when :workspace then workspace_path
    when :cadence   then channels_path
    else                 public_send("#{app.key}_root_path")
    end
  end

  # A single left-rail nav row. Active rows get a raised surface + accent glyph;
  # the rail morphs on Turbo navigation so this stays in sync without JS.
  def shell_nav_link(label, path, icon:, active: false, key: nil)
    base = "flex items-center gap-2.5 rounded-md px-2.5 py-1.5 text-sm font-medium transition"
    state = active ? "bg-[var(--color-surface)] text-[var(--color-ink)] shadow-sm ring-1 ring-[var(--color-hairline)]" :
                     "text-[var(--color-ink-soft)] hover:bg-[var(--color-cool-100)] hover:text-[var(--color-ink)]"
    link_to path, data: { turbo_action: "advance" }, class: "#{base} #{state}" do
      glyph = key ? content_tag(:span, key, class: "grid h-4 w-4 place-items-center font-mono text-[10px] font-semibold") :
                    ws_icon(icon)
      safe_join([
        content_tag(:span, glyph, class: active ? "text-[var(--color-accent)]" : "text-[var(--color-ink-faint)]"),
        label
      ])
    end
  end
end
