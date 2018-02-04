require 'base64'
require 'sinatra'
require 'sinatra/reloader'
require 'faye/websocket'
require 'byebug'

require_relative 'src/my_logger'
require_relative 'src/req_allocator'
require_relative 'src/client'
require_relative 'src/room'

Faye::WebSocket.load_adapter('thin')

set :bind, "0.0.0.0"
set :port, 8080

# TODO: GC
$rooms = []
$req_allocator = ReqAllocator.instance
$logger = MyLogger.instance

get '/' do
  redirect "/index.html"
end


# 初期化データ
# pdf: data, hash: hoge
post '/init' do
  # きたデータをいい感じに
  # # TODO: err系をsession/flashとかで画面にフィード
  redirect "/" unless pdf_field=params[:pdf]
  redirect "/" unless file=pdf_field[:tempfile]
  bin_pdf = file.read
  pdf = Base64.encode64(bin_pdf)
  hash_tag = params[:hash_tag]
  redirect "/" unless hash_tag

  # room_idと合わせて保持
  room = Room.new pdf, hash_tag
  $rooms << room

  # session_id失うとadminも失うのでwww
  res_hash = {"room_id": room.room_id, "session_id": room.session_id}
  $logger.std_log "room gen: #{room.room_id}"

  return res_hash.to_json
end


# room_idのpdfを返す
get '/pdf/:room_id' do |room_id|
  # roomがあるか確認
  room = $req_allocator.find_room(room_id)
  
  if room
    $logger.std_log "required pdf: #{room_id}"
    response.headers['content-type'] = "application/pdf"
    response.write Base64.decode64(room.get_pdf)
  else
    "room not found"
  end
end


# 色々
get '/ws' do
  if Client.websocket?(request.env)
    # faye-websockのobjに
    ws = Client.new(request.env)

    # socketをそのまま
    ws.on :open do
      $logger.std_log "conn open"
      ws.send_hash({"state": "ok"})
    end

    # 認証してからメッセージング
    ws.on :message do |msg|
      req = msg.data
      $logger.std_log "get message: #{req}"

      res = $req_allocator.allocate ws, req
      # TODO: err/log
      ws.send_hash(res) if res
    end

    # socket殺す
    ws.on :close do
      # 参照先userを確認
      room = ws.user&.room
      # userの退出処理，細部はroomに
      room.exit_someone ws.user if room

      $logger.std_log "conn close"
    end

    ws.rack_response
  else
    "websock request required."
  end
end
