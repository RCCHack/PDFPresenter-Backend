require 'base64'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra-websocket'
require 'byebug'

require_relative 'src/room'

set :bind, "0.0.0.0"
set :port, 8080
set :sockets, []


$rooms = []


get '/' do
  redirect "/index.html"
end


# 初期化データ
# pdf: data, hash: hoge
post '/init' do
  # きたデータをいい感じに
  bin_pdf = params[:pdf][:tempfile].read
  pdf = Base64.encode64(bin_pdf)
  hash_tag = params[:hash_tag]

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
    res_hash = {"err": "room not found"}
  end

  return res_hash.to_json
end


# 色々
get '/ws' do
  puts "get /ws"
  if request.websocket?
    puts "get websock"

    request.websocket do |ws|
      # socketをそのまま
      ws.onopen do
        settings.sockets << ws
        ws.send '{"state": "ok"}'
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
