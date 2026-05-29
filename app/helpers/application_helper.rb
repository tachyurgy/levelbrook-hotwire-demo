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
    "inbox"     => '<path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>'
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
end
