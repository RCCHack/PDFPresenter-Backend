require 'bindata'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra-websocket'

set :bind, "0.0.0.0"
set :port, 8080
set :sockets, []


$rooms = []


get '/' do
  
end


# 初期化データ
# pdf: data, hash: hoge
post '/init' do
  # track streamを作成
  # room_idと合わせて保持
  room = Room.new pdf, hash_tag
  $rooms << room

  # session_id失うとadminも失うのでwww
  res_hash = {"room_id": room.room_id, "session_id": room.session_id}

  return res_hash.to_json
end


# room_idのpdfを返す
get '/pdf/:room_id' do |room_id|
  # roomがあるか確認
  room = find_room(room_id)
  
  if room
    res_hash = {"pdf": room_pdf}
  else
    res_hash = {"room not found"}
  end

  return res_hash.to_json
end


# 色々
get '/ws' do
  if request.websocket?
    request.websocket do |ws|
      # socketをそのまま
      ws.onopen do
        settings.sockets << ws
      end

      # 認証してからメッセージング
      ws.onmessage do |msg|
        ReqAllocator.instance.allocate ws, msg
      end

      # socket殺す
      ws.onclose do
        settings.sockets.delete(ws)
        # TODO: wsにuser参照つけて，殺す
      end
    end
  end
end
