module ForgeHelper
  # Render +string+ with the fuzzy-matched character indices highlighted — the
  # picker-style affordance fzy_score#match positions exist for. Output is safe
  # HTML; characters are individually escaped via content_tag / h.
  def fzy_highlight(string, positions)
    set = Array(positions)
    safe_join(string.to_s.chars.each_with_index.map do |ch, i|
      if set.include?(i)
        content_tag(:span, ch, class: "rounded-sm bg-[var(--color-accent-soft)] font-semibold text-[var(--color-accent)]")
      else
        ch
      end
    end)
  end

  # A compact, readable score badge (fzy scores are unbounded floats).
  def fzy_score_badge(score)
    return content_tag(:span, "no match", class: "font-mono text-[10px] text-[var(--color-ink-faint)]") if score.nil?

    content_tag :span, format("%.2f", score),
      class: "font-mono text-[10px] tabular-nums text-[var(--color-ink-soft)]"
  end
end
