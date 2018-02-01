require 'json'
require 'singleton'

# reqをhogehoge
class ReqAllocator < Singleton

  def initialize
    @rooms = []
  end

  # req受けて処理
  def allocate socket, req_json
    req_hash = parse_json req_json

    case req_hash["type"]
    
    # adminがopen
    when "open" then
      # 存在検証
      room_id = req_hash["room_id"]
      return false unless room_id
      room_id = req_hash["session_id"]
      return false unless session_id

      # session_idで検証
      room = find_room room_id
      return false unless room&.session_id==session_id

      # room開始
      admin = User.new(socket, admin=true)
      room.add_admin admin

    # パンピーが参加
    when "join" then
      room_id = req_hash["room_id"]
      return false unless room_id

      # session_idで検証
      room = find_room room_id
      return false unless room

      # roomに新規ユーザ突っ込んで，現在page送信
      user = User.new(socket, admin=false)
      room.add_user user
      user.send_page room.page

    when "slide" then
      # TODO: wsからuser逆引き
      room = ws.user.room
      room.update_page page
    else

    end
  end

  private

  # return room_id's room / nil
  def find_room room_id
    @rooms.each do |r|
      return r if r.room_id==room_id
    end

    return nil
  end

  # return parsed hash / nil
  def parse_json req_json
    req_hash = nil
    begin
      req_hash = JSON.parse req_json
    rescue JSONParseError => e
      puts e
      req_hash = nil
    end

    return req_hash
  end

end
