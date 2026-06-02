require "test_helper"

module Api
  module V1
    class BadAudioReportsControllerTest < ActionDispatch::IntegrationTest
      KEY = BadAudioReportsController::API_KEY

      test "rejects a request with no API key" do
        assert_no_difference "BadAudioReport.count" do
          post api_v1_bad_audio_reports_path, params: { clip_id: "yt-fra-abc-1" }
        end
        assert_response :unauthorized
      end

      test "rejects a request with a wrong API key" do
        assert_no_difference "BadAudioReport.count" do
          post api_v1_bad_audio_reports_path,
               params: { clip_id: "yt-fra-abc-1" },
               headers: { "X-Api-Key" => "nope" }
        end
        assert_response :unauthorized
      end

      test "records a valid report" do
        assert_difference "BadAudioReport.count", 1 do
          post api_v1_bad_audio_reports_path,
               params: { clip_id: "yt-fra-abc-1", clip_url: "/sentence-clips/x.mp3",
                         lang: "fra", lang_name: "French", reason: "dead air", page_url: "https://lingua.levelbrook.com/" },
               headers: { "X-Api-Key" => KEY }
        end
        assert_response :created
        body = JSON.parse(response.body)
        assert body["ok"]
        report = BadAudioReport.last
        assert_equal "yt-fra-abc-1", report.clip_id
        assert_equal "open", report.status
      end

      test "422 when clip_id is missing" do
        post api_v1_bad_audio_reports_path,
             params: { reason: "no clip id" },
             headers: { "X-Api-Key" => KEY }
        assert_response :unprocessable_entity
        assert_not JSON.parse(response.body)["ok"]
      end

      test "preflight answers CORS for an allowed origin" do
        process :options, api_v1_bad_audio_reports_path,
                headers: { "Origin" => "https://lingua.levelbrook.com" }
        assert_response :no_content
        assert_equal "https://lingua.levelbrook.com", response.headers["Access-Control-Allow-Origin"]
        assert_match "POST", response.headers["Access-Control-Allow-Methods"]
      end
    end
  end
end
