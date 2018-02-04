require 'json'
require 'singleton'

# reqをhogehoge
class ReqAllocator
  include Singleton

  # req受けて処理
  def allocate socket, req_json
    req_hash = parse_json req_json
    return res_error("invalid json") unless req_hash


    case req_hash["type"]
    # adminがopen
    when "open" then
      # 存在検証
      room_id = req_hash["room_id"]
      return res_error("room_id require") unless room_id
      session_id = req_hash["session_id"]
      return res_error("session_id require") unless session_id

      # session_idでroomを検証
      room = find_room room_id
      return res_error("invalid session_id") unless room&.session_id==session_id

      # room開始
      admin = User.new(socket, privilege=true)
      room.set_admin admin

    # パンピーが参加
    when "join" then
      # 存在検証
      room_id = req_hash["room_id"]
      return res_error("room_id require") unless room_id

      # room検証
      room = find_room room_id
      return res_error("unknown room") unless room

      # roomに新規ユーザ突っ込んで，現在page送信
      user = User.new(socket, privilege=false)
      room.add_user user
      user.send_page room.page

    when "slide" then
      # TODO: wsからuser逆引き
      # 正当性確認
      user = ws.user
      return res_error("conn require") unless user
      room = user.room
      return res_error("should into room") unless room

      # 権限確認
      return res_error("you aren't admin") unless room.admin==user

      room.update_page page
    else
      return res_error("invalid type")
    end
  end

  # return room_id's room / nil
  def find_room room_id
    $rooms.each do |r|
      return r if r.room_id==room_id
    end

    return nil
  end

  # 汎用
  def res_error text
    {"err": text}
  end

  private

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
