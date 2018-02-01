require_relative 'src/user'

# 配信ルーム
class Room
  attr_reader :session_id, :room_id, :page

  # pdfを元に 
  # 初期生成データ，stream確立
  def initialize pdf, hash_tag
    # adminユーザとその他
    @admin = nil
    @users = []

    # postされたpdfとハッシュタグ(#抜き)
    @pdf = pdf
    @page = 1
    @hash_tag = hash_tag

    # 内部生成でええやろ(適当)
    @session_id = SecureRandom.hex() 
    @room_id = (0...5).map{ ('A'..'Z').to_a[rand(26)] }.join

    @stream = establish_stream @hash_tag
  end

  # adminユーザ追加
  def add_admin admin
    return false unless admin.admin
    @admin = admin
    admin.room = self
  end

  # normalユーザ追加
  def add_user user
    users << user
    user.room = self
  end

  # page更新を反映・通知
  def update_page page
    @page = page
    # パンピーに送信
    @users.each do |u|
      u.send_page page
    end
  end

  private
  def establish_stream hash_tag
    # track stream作ってね★
  end

end
