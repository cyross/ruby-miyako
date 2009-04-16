# 画像ビット操作サンプル
# 2009.4.17 Cyross Makoto

require 'Miyako/miyako'

include Miyako

# 画像が画面をはみ出そうになったら移動量を+-反転
# spr:: 移動対象のスプライト
# amt:: 移動量配列
# 返却値:: 変更した移動量配列
def turn(spr, amt)
  amt[0] = -amt[0] if (spr.x + spr.ow) >= Screen.w
  amt[0] = -amt[0] if spr.x <= 0
  amt[1] = -amt[1] if (spr.y + spr.oh) >= Screen.h
  amt[1] = -amt[1] if spr.y <= 0
  return amt
end

# マスク画像を作成
bmask = Sprite.new(:size=>Size.new(100,100), :type=>:ac)
Drawing.circle(bmask, [50,50], 50, [255,255,255], :fill)

# 描画用スプライトを作成
spr1 = Sprite.new(:size=>Size.new(100,100), :type=>:ac)
spr2 = Sprite.new(:size=>Size.new(100,100), :type=>:ac)
spr3 = Sprite.new(:size=>Size.new(100,100), :type=>:ac)

# 転送元背景を準備
bk = Sprite.new(:file=>"Animation1/m1ku_back.jpg", :type=>:as)
text = Sprite.new(:file=>"text.png", :type=>:ac)
# 表示用背景を準備(元画像を反転)
bk2 = bk.inverse

spr2.centering
spr3.right.bottom

# 移動量配列を設定
@amt1 = [ 4, 4]
@amt2 = [ 4,-4]
@amt3 = [-4,-4]

# Main Routine
Miyako.main_loop do
  break if Input.quit_or_escape?
  # マスク画像の転送
  bmask.render_to(spr1)
  bk.render_to(spr2){|src, dst| src.ox = spr2.x; src.oy = spr2.y}
  bk2.render_to(spr3){|src, dst| src.ox = spr3.x; src.oy = spr3.y}
  # 元画像をandして描画用スプライトへ転送
  spr1.and!(bk){|src, dst| src.ox = spr1.x; src.oy = spr1.y}
  # 元画像をorして描画用スプライトへ転送
  spr2.or!(text)
  # 元画像をxorして描画用スプライトへ転送
  spr3.xor!(text)
  
  # 画像を画面に描画
  bk2.render
  spr1.render
  spr2.render
  spr3.render
  # スプライトの移動
  spr1.move(*@amt1)
  spr2.move(*@amt2)
  spr3.move(*@amt3)
  # 画像が画面をはみ出そうになったら移動量を+-反転
  @amt1 = turn(spr1, @amt1)
  @amt2 = turn(spr2, @amt2)
  @amt3 = turn(spr3, @amt3)
end
