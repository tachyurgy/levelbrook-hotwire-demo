class Choice < ApplicationRecord
  belongs_to :scene
  has_one :story, through: :scene

  validates :label, :target_key, presence: true

  scope :ordered, -> { order(:position) }

  # Record a reader's pick and broadcast the updated tally to everyone reading
  # this scene. We use an explicit Turbo Stream broadcast (not refresh) because
  # only one small fragment changes — the live "% of readers chose this" bar —
  # and we want it to update without navigating anyone off their current scene.
  def record_pick!
    increment!(:picks_count)
    broadcast_tally_later
  end

  # Percent of readers (at this scene) who picked this choice.
  def share
    total = scene.choices.sum(:picks_count)
    return 0 if total.zero?

    ((picks_count.to_f / total) * 100).round
  end

  def target_scene
    scene.story.scene(target_key)
  end

  private
    def broadcast_tally_later
      broadcast_replace_later_to(
        [ scene.story, scene, :tally ],
        target: "scene_#{scene.id}_tally",
        partial: "stories/tally",
        locals: { scene: scene }
      )
    end
end
