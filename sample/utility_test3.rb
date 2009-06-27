# encoding: utf-8
# Utility.product_positionサンプル
# 内部では実数(Utility.product_position_f)で算出
# 2009.4.19 Cyross Makoto

require 'Miyako/miyako'

# 色配列(Enumerator)
colors = [[0,0,255],   # 青色
          [0,255,0],   # 緑色
          [0,255,255], # 水色
          [255,0,0],   # 赤色
          [255,0,255], # 紫色
          [255,255,0]  # 黄色
         ].cycle

# 矩形サイズの設定
size = 16

# コリジョンの設定
collision = Miyako::Collision.new(Miyako::Rect.new(0,0,size,size))
position  = Miyako::Point.new(0, 0)
amount    = 4

# メインループの開始
loop do
  Miyako::Input.update
  # Escキー押下もしくは×印クリックのときは終了
  break if Miyako::Input.quit_or_escape?

  # キャラの位置の更新
  # キーが押されたとき、移動先が画面の範囲内なら移動
  # [仮移動量,座標,コリジョンサイズ,画面サイズ] の形式で取り込んで、Utility.in_bounds?メソッドで判定
  move_amount = Miyako::Input.trigger_amount.map{|v| v * amount}. # 入力値 * amount = 仮移動量
                zip(position, collision.rect.size, Miyako::Screen.size).
                map{|qual| 
                  Miyako::Utility.in_bounds?(
                      [qual[1],qual[1]+qual[2]-1],
                      [0, qual[3]-1],
                      qual[0]
                  ) ? qual[0] : 0
                }
  position.move!(*move_amount)
  
  # 矩形上の位置の組み合わせを求める
  # 内部では実数で算出
  array = Miyako::Utility.product_position_f(position,collision.rect,[size,size])
  
  # 画面の描画
  # 画面の消去
  Miyako::Screen.clear

  # 当たり判定の表示
  array.each{|pos|
    Miyako::Drawing.rect(Miyako::Screen, pos+[size,size], colors.next)
  }
  
  # 現在操作しているキャラの表示
  Miyako::Drawing.rect(Miyako::Screen, position.to_a+collision.rect.size, [255,255,255])

  # 画面の更新
  Miyako::Screen.render
end

