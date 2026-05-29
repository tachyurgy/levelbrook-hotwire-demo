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
end
