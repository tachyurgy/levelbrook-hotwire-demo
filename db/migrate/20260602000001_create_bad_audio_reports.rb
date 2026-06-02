class CreateBadAudioReports < ActiveRecord::Migration[8.1]
  def change
    create_table :bad_audio_reports do |t|
      t.string  :clip_id, null: false
      t.string  :clip_url
      t.string  :lang
      t.string  :lang_name
      t.string  :reason
      t.string  :page_url
      t.string  :user_agent
      t.string  :status, null: false, default: "open"

      t.timestamps
    end

    add_index :bad_audio_reports, :clip_id
    add_index :bad_audio_reports, :status
  end
end
