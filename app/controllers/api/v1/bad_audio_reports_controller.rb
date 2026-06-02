module Api
  module V1
    # Tiny JSON ingest for LinguaGuessr's "Report bad audio" button. Lives apart
    # from the showcase apps: lean ActionController::API (no CSRF token, no
    # browser gate, no demo cookies), guarded by a single shared API key and a
    # CORS allowlist for the LinguaGuessr origin.
    class BadAudioReportsController < ActionController::API
      # Shared secret. A spam deterrent, not real auth — the key ships in the
      # LinguaGuessr client bundle. Override in prod via BAD_AUDIO_API_KEY.
      API_KEY = ENV.fetch("BAD_AUDIO_API_KEY", "lb_lingua_f7ccce410a103c600c4bf1947a93fc9c").freeze

      # Origins allowed to call this endpoint from a browser.
      ALLOWED_ORIGINS = [
        "https://lingua.levelbrook.com",
        "http://localhost:5173",
        "http://localhost:4173"
      ].freeze

      before_action :set_cors_headers
      # Never auth the preflight — it carries no key, only the CORS handshake.
      before_action :authenticate!, except: :preflight

      # Browser preflight (OPTIONS) — answer the CORS handshake, never auth it.
      def preflight
        head :no_content
      end

      def create
        report = BadAudioReport.new(report_params)
        report.user_agent = request.user_agent

        if report.save
          render json: { ok: true, id: report.id }, status: :created
        else
          render json: { ok: false, errors: report.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      private

      def report_params
        params.permit(:clip_id, :clip_url, :lang, :lang_name, :reason, :page_url)
      end

      def set_cors_headers
        origin = request.headers["Origin"]
        if ALLOWED_ORIGINS.include?(origin)
          response.set_header("Access-Control-Allow-Origin", origin)
          response.set_header("Vary", "Origin")
        end
        response.set_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        response.set_header("Access-Control-Allow-Headers", "Content-Type, X-Api-Key")
        response.set_header("Access-Control-Max-Age", "86400")
      end

      def authenticate!
        provided = request.headers["X-Api-Key"].to_s
        return if ActiveSupport::SecurityUtils.secure_compare(provided, API_KEY)

        render json: { ok: false, error: "unauthorized" }, status: :unauthorized
      end
    end
  end
end
