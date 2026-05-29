module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :member_name

    def connect
      self.member_name = cookies.encrypted[:member_name].presence || "Guest"
    end
  end
end
