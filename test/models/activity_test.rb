require "test_helper"

# Activity is a synthetic, memoized feed assembled from real records — so every
# test resets the class-level cache before and after touching it.
class ActivityTest < ActiveSupport::TestCase
  setup do
    Activity.reset!
    project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @col = project.columns.create!(name: "To Do", position: 0)
    @channel = Channel.create!(name: "general", slug: "general")
  end

  teardown { Activity.reset! }

  test "aggregates issues, comments and messages into one feed" do
    issue = @col.issues.create!(title: "Ship it")
    issue.comments.create!(body: "looks good")
    @channel.messages.create!(body: "hello team")
    Activity.reset!

    icons = Activity.all.map(&:icon)
    assert_includes icons, "issue"
    assert_includes icons, "comment"
    assert_includes icons, "chat"
    assert_equal 3, Activity.total
  end

  test "feed is sorted newest first" do
    @col.issues.create!(title: "old")
    travel 2.seconds do
      @col.issues.create!(title: "new")
    end
    Activity.reset!

    ats = Activity.all.map(&:at)
    assert_equal ats.sort.reverse, ats
  end

  test "page slices the feed and is empty past the end" do
    5.times { |i| @col.issues.create!(title: "I#{i}") }
    Activity.reset!

    assert_equal 2, Activity.page(1, 2).size
    assert_equal 2, Activity.page(2, 2).size
    assert_equal 1, Activity.page(3, 2).size
    assert_equal [], Activity.page(99, 2)
  end

  test "reset! clears the memoized feed" do
    @col.issues.create!(title: "one")
    Activity.reset!
    assert_equal 1, Activity.total

    @col.issues.create!(title: "two")
    assert_equal 1, Activity.total, "memoized feed is stale until reset"

    Activity.reset!
    assert_equal 2, Activity.total
  end
end
