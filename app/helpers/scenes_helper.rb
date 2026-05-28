module ScenesHelper
  # Each mood drives the scene's ambient gradient. Full class strings so the
  # Tailwind scanner keeps them.
  MOOD_BACKDROPS = {
    "calm"   => "from-slate-900 via-slate-950 to-slate-950",
    "tense"  => "from-amber-950/40 via-slate-950 to-slate-950",
    "eerie"  => "from-violet-950/50 via-slate-950 to-slate-950",
    "hopeful" => "from-emerald-950/40 via-slate-950 to-slate-950",
    "grim"   => "from-slate-800/60 via-slate-950 to-black"
  }.freeze

  def mood_backdrop(scene)
    MOOD_BACKDROPS.fetch(scene.mood, MOOD_BACKDROPS["calm"])
  end
end
