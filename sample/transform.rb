# -*- encoding: utf-8 -*-
# 画像拡大・縮小・回転サンプル
# 2009.4.12 Cyross Makoto

require 'Miyako/miyako'

include Miyako

Screen::fps_view = true

MAX = 8.0 # 最大拡大率8倍
MIN = -8.0 # 最小拡大率8分の1
RATE = 0.4 # 拡大率間隔0.4倍

@sprite = Sprite.new(:file=>"map_test/map.png", :type=>:ck).centering

# 変形対象画像を半透明にする
Bitmap.dec_alpha!(@sprite, 0.5)

# スプライトの変形中心を設定
@sprite.center_x = @sprite.ow/2
@sprite.center_y = @sprite.oh/2

# 回転角度単位を30度に設定(ラジアンに変換)
@rate  = Math::PI * 2.0 * 30.0 / 360.0

xscale = 4.0 # 初期拡大率(x座標)4倍
yscale = 4.0 # 初期拡大率(y座標)4倍
angle = 0.0  # 初期回転角度0度

# 画面の中心に画像を表示指定(pre_render)
Screen.pre_render_array << [Sprite.new(:file=>"Animation1/m1ku_back.jpg", :type=>:ac).centering, @sprite]

# 画面の変形中心を設定
Screen.center_x = Screen.w/2
Screen.center_y = Screen.h/2

Miyako.main_loop do
  break if Input.quit_or_escape?
	Screen.pre_render
  # 回転
#  Bitmap.rotate(@sprite, Screen, angle)
  # 拡大/縮小
#  Bitmap.scale(@sprite, Screen, xscale, yscale)
  # 回転/拡大/縮小
  Bitmap.transform(@sprite, Screen, angle, xscale, yscale)
  # 拡大縮小率の変更
	xscale -= RATE
	xscale = MAX if xscale < MIN
	yscale -= RATE
	yscale = MAX if yscale < MIN
  # 回転角度の変更
  angle = (angle + @rate) % (Math::PI*2.0)
end
