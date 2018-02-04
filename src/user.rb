require 'json'

# socketデータを包んで
class User
  # @socket
  # @admin
  # @room
  attr_accessor :room, :privilege
  
  # 拡張を考慮
  def initialize socket, privilege=false
    @socket = socket
    # うーんこの
    @privilege = privilege
  end

  # hashから
  def send_hash req_hash
    @socket.send_hash req_hash
  end

  # comment送信
  def send_comment comment
    req_hash = {
      "comment": comment
    }

    send_hash req_hash
  end

  # スライドめくり
  def send_page page
    req_hash = {
      "page": page
    }

    send_hash req_hash
  end

  # roomの終了
  def send_finish
    req_hash = {
      "state": "close"
    }

    send_hash req_hash
  end
end
