require 'json'
require 'singleton'

# reqをhogehoge
class ReqAllocator
  include Singleton

  # req受けて処理
  def allocate socket, req_json
    req_hash = parse_json req_json
    return false unless req_hash

    case req_hash["type"]
    # adminがopen
    when "open" then
      # 存在検証
      room_id = req_hash["room_id"]
      return false unless room_id
      session_id = req_hash["session_id"]
      return false unless session_id

      # session_idでroomを検証
      room = find_room room_id
      return false unless room&.session_id==session_id

      # room開始
      admin = User.new(socket, privilege=true)
      room.set_admin admin

    # パンピーが参加
    when "join" then
      # 存在検証
      room_id = req_hash["room_id"]
      return false unless room_id

      # room検証
      room = find_room room_id
      return false unless room

      # roomに新規ユーザ突っ込んで，現在page送信
      user = User.new(socket, privilege=false)
      room.add_user user
      user.send_page room.page

    when "slide" then
      # TODO: wsからuser逆引き
      # 正当性確認
      user = ws.user
      return false unless user
      room = user.room
      return false unless room

      # 権限確認
      return false unless room.admin==user

      room.update_page page
    else
      return false
    end
  end

  private

  # return room_id's room / nil
  def find_room room_id
    $rooms.each do |r|
      return r if r.room_id==room_id
    end

    return nil
  end

  # return parsed hash / nil
  def parse_json req_json
    req_hash = nil
    begin
      req_hash = JSON.parse req_json
    rescue JSON::ParserError => e
      puts "parse error #{e.to_s}"
      req_hash = nil
    end

    return req_hash
  end

end
