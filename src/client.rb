require 'json'
require 'faye/websocket'

require 'json'
require 'faye/websocket'

# WebSock拡張してuserとの関連を容易に
class Client < Faye::WebSocket
  attr_accessor :user
  
  def initialize(env)
    super(env)
  end

  # hashで受けて，jsonにして送信
  def send_hash res_hash
    res_json = res_hash.to_json

    send res_json
  end

  # TODO: room_gameはclose_process実装
  # 切断時の処理
  def close_process()
    # user持ってなければ問題なし
    return unless @user

    # user持ってたら所属に処理を頼む
    @space&.close_user(@user)
    
    debug_log("closed: #{@user.class}[#{@user.name}]")
  end
  
end
