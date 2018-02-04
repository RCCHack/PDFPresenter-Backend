require 'base64'
require 'sinatra'
require 'sinatra/reloader'
require 'faye/websocket'
require 'byebug'

require_relative 'src/req_allocator'
require_relative 'src/room'

Faye::WebSocket.load_adapter('thin')

set :bind, "0.0.0.0"
set :port, 8080

# TODO: GC
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
    res_hash = {"pdf": room.get_pdf}
  else
    res_hash = {"err": "room not found"}
  end

  return res_hash.to_json
end


# 色々
get '/ws' do
  if Faye::WebSocket.websocket?(request.env)
    # faye-websockのobjに
    ws = Faye::WebSocket.new(request.env)

    # socketをそのまま
    ws.on :open do
      ws.send '{"state": "ok"}'
    end

    # 認証してからメッセージング
    ws.on :message do |msg|
      res = ReqAllocator.instance.allocate ws, msg.data
      # TODO: err/log
    end

    # socket殺す
    ws.on :close do
      # TODO: wsにuser参照つけて，殺す
      # TODO: userがadminならroomも殺す
    end

    ws.rack_response
  else
    "websock request required."
  end
end
