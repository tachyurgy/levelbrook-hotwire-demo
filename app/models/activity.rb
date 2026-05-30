# A synthetic, read-only activity feed assembled from real workspace records
# (issues created/updated, comments, messages). No table — it exists to power
# the infinite-scroll / lazy-frame demo over genuine data.
class Activity
  Item = Struct.new(:icon, :actor, :verb, :subject, :context, :at, keyword_init: true)

  class << self
    # Rebuilt on every call so the feed always reflects the latest records — a
    # new chat message, comment, or moved issue shows up immediately. The source
    # tables are tiny, so the handful of queries is cheap. (Previously this was
    # memoized at class level, which meant a long-running process served a stale
    # feed until a manual reset; for a real high-traffic feed you'd cache this
    # under a key derived from max(updated_at) of the source tables instead.)
    def all
      build.sort_by(&:at).reverse
    end

    # Retained as a no-op: the feed is now rebuilt on every read, so there is no
    # cache to clear. Kept so existing callers/tests stay valid and to document
    # that staleness is no longer a concern.
    def reset! = nil

    def total = all.size

    def page(number, per)
      offset = (number - 1) * per
      all[offset, per] || []
    end

    private

    def build
      items = []

      Issue.includes(:assignee, column: :project).find_each do |issue|
        items << Item.new(
          icon: "issue", actor: issue.assignee&.name || "Unassigned",
          verb: "moved", subject: "#{issue.key} #{issue.title}",
          context: issue.column.name, at: issue.updated_at
        )
      end

      Comment.includes(:member, :issue).find_each do |comment|
        items << Item.new(
          icon: "comment", actor: comment.member&.name || "Someone",
          verb: "commented on", subject: comment.issue.key,
          context: comment.body.truncate(60), at: comment.created_at
        )
      end

      Message.includes(:member, :channel).order(created_at: :desc).limit(60).each do |message|
        items << Item.new(
          icon: "chat", actor: message.member&.name || "Someone",
          verb: "posted in", subject: "##{message.channel.name}",
          context: message.body.truncate(60), at: message.created_at
        )
      end

      items
    end
  end
end
