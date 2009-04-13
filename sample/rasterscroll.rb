# encoding: utf-8
# ラスタスクロールサンプル
# 2009.4.12 Cyross Makoto

require 'Miyako/miyako'
require 'Miyako/EXT/raster_scroll'

include Miyako

#1秒後にラスタスクロールのフェードアウトを設定する
wait = WaitCounter.new(1.0).start
# 0.05秒ごとに、2ラインずつ、8ピクセル単位のラスタスクロールを行う
sprite = Sprite.new(:file => "Animation2/lex_body.png", :type => :ck).centering
rs = RasterScroll.new(sprite).start({:lines => 2, :size => 8, :wait=>WaitCounter.new(0.05)})
fade = false

Miyako.main_loop do
  break if Input.quit_or_escape?
  rs.effecting? ? rs.update.render : sprite.render
  if fade == false && wait.finish?
    #1秒後ごとに、ラスタスクロールの幅を縮める
    rs.fade_out(1, WaitCounter.new(1.0))
    fade = true
  end
end