# 画像ビット操作サンプル
# 2009.4.17 Cyross Makoto

require 'Miyako/miyako'

include Miyako

# マスク画像を作成
bmask = Sprite.new(:size=>Size.new(100,100), :type=>:ac)
Drawing.circle(bmask, [50,50], 50, [255,255,255], :fill)

# 描画用スプライトを作成
back = Sprite.new(:size=>Size.new(100,100), :type=>:ac)

# 転送元背景を準備
bk = Sprite.new(:file=>"Animation1/m1ku_back.jpg", :type=>:as)
# 表示用背景を準備(元画像を反転)
bk2 = bk.inverse

# 移動量を設定
amt = [4,4]

# Main Routine
Miyako.main_loop do
  break if Input.quit_or_escape?
  # マスク画像の転送
  bmask.render_to(back)
  # 元画像をandして描画用スプライトへ転送
  back.and!(bk){|src, dst| src.ox = back.x; src.oy = back.y}
  
  # 画像を画面に描画
  bk2.render
  back.render
  # スプライトの移動
  back.move(*amt)
  # 画像が画面をはみ出そうになったら移動量を+-反転
  amt[0] = -amt[0] if (back.x + back.ow) >= Screen.w
  amt[0] = -amt[0] if back.x <= 0
  amt[1] = -amt[1] if (back.y + back.oh) >= Screen.h
  amt[1] = -amt[1] if back.y <= 0
end
