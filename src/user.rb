require 'json'

# socketデータを包んで
class User
  # @socket
  # @admin
  # @room
  attr_reader :room, :admin
  
  # 拡張を考慮
  def initialize socket, admin=false
    @socket = socket
    # うーんこの
    @admin = admin
  end

  # roomを設定
  def entry_room room
    @room = room
  end

  def send_hash req_hash
    req_json = req_hash.to_json

    sockets.send req_json

    return req_json
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
