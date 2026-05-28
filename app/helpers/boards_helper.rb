module BoardsHelper
  # Static, explicit Tailwind classes per accent token. Listed in full (not
  # interpolated) so Tailwind's content scanner keeps them in the build.
  COLUMN_ACCENTS = {
    "slate"   => { dot: "bg-slate-400",   header: "text-slate-300",   ring: "ring-slate-500/20" },
    "sky"     => { dot: "bg-sky-400",     header: "text-sky-300",     ring: "ring-sky-500/20" },
    "violet"  => { dot: "bg-violet-400",  header: "text-violet-300",  ring: "ring-violet-500/20" },
    "amber"   => { dot: "bg-amber-400",   header: "text-amber-300",   ring: "ring-amber-500/20" },
    "emerald" => { dot: "bg-emerald-400", header: "text-emerald-300", ring: "ring-emerald-500/20" },
    "rose"    => { dot: "bg-rose-400",    header: "text-rose-300",    ring: "ring-rose-500/20" }
  }.freeze

  def column_accent(column, part)
    COLUMN_ACCENTS.fetch(column.accent, COLUMN_ACCENTS["slate"])[part]
  end

  TAG_COLORS = {
    "frontend" => "bg-sky-500/15 text-sky-300",
    "backend"  => "bg-violet-500/15 text-violet-300",
    "infra"    => "bg-amber-500/15 text-amber-300",
    "realtime" => "bg-emerald-500/15 text-emerald-300",
    "research" => "bg-rose-500/15 text-rose-300"
  }.freeze

  def tag_pill_class(tag)
    TAG_COLORS.fetch(tag, "bg-slate-500/15 text-slate-300")
  end
end
