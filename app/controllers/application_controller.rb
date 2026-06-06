class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_member, :current_app

  before_action :assign_current_app

  # The themeable shell re-skins its chrome (accent + nav) per app. We infer the
  # app from the controller path: namespaced controllers (relay/, forge/) resolve
  # from their namespace; the gallery stays chromeless; every other top-level
  # controller is the workspace.
  def assign_current_app
    segment = controller_path.split("/").first
    key =
      case segment
      when "relay", "forge" then segment.to_sym
      when "gallery"        then nil
      else                       :workspace
      end
    @current_app = Showcase.find(key) if key
  end

  def current_app
    @current_app
  end

  # Demo identity: pick a stable workspace member for this browser so chat,
  # comments and presence are attributed. Persisted in an encrypted cookie that
  # ActionCable's Connection also reads.
  def current_member
    @current_member ||= begin
      member =
        if (id = cookies.encrypted[:member_id]).present?
          Member.find_by(id: id)
        end
      member ||= Member.order(:id).first
      if member
        cookies.encrypted.permanent[:member_id] = member.id
        cookies.encrypted.permanent[:member_name] = member.name
      end
      member
    end
  end

  def switch_member(member)
    @current_member = member
    cookies.encrypted.permanent[:member_id] = member.id
    cookies.encrypted.permanent[:member_name] = member.name
  end
end
