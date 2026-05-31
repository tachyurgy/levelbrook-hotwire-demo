class AddAudioToSpindle < ActiveRecord::Migration[8.1]
  def change
    # A track is either live-synthesized (audio_url is null, the synth engine
    # renders it from `roots`/`texture`) or file-backed (audio_url points at a
    # real CC0 recording in /public/spindle). roots is therefore optional now.
    add_column :spindle_tracks, :audio_url, :string
    change_column_null :spindle_tracks, :roots, true

    # "synth" = generated live in the browser; "stream" = real CC0 audio file.
    add_column :spindle_albums, :kind, :string, default: "synth", null: false
  end
end
