# Utility.product_linerサンプル
# 2009.4.12 Cyross Makoto

require 'Miyako/miyako'

# 色配列(Enumerator)
Colors = [[0,0,255],    # 青色
          [0,255,0],    # 緑色
          [0,255,255],  # 水色
          [255,0,0],    # 赤色
          [255,0,255],  # 紫色
          [255,255,0],  # 黄色
          [255,255,255] # 白色
         ].cycle

# 線形配列生成メソッドを用意
def draw_liner(sprite, info)
  # 画面の真ん中から指定の位置までの線形配列を、
  # 1～16間ランダム値の刻みで作成する
  square = Miyako::Square.new(
             Miyako::Screen.w/2, Miyako::Screen.h/2,
             rand(Miyako::Screen.w), rand(Miyako::Screen.h)
           )
  amount = rand(16)+1
  # 線形配列を作成
  array = Miyako::Utility.product_liner_by_square(square, amount)
  # 画像内容の消去
  sprite.fill([0,0,0,0])
  # 配列の位置を元に矩形を描画
  array.each{|pos| Miyako::Drawing.rect(sprite, pos+[amount,amount], Colors.next)}
  
  info.dispose if info
  info = Miyako::Shape.text(
           :font => Miyako::Font.serif,
           :text => "square = (#{square[0]}, #{square[1]})-(#{square[2]}, #{square[3]}), amount = #{amount}"
         )
         
  [sprite, info]
end

# 描画間隔の設定(ここでは2秒)
wait = Miyako::WaitCounter.new(2)

# 描画用スプライトの作成
screen = Miyako::Sprite.new(
  :size=>Miyako::Screen.size,
  :type=>:ac
)

# 情報表示用スプライト変数の用意
screen, info = draw_liner(screen, nil)

# メインループの開始
loop do
  Miyako::Input.update
  # Escキー押下もしくは×印クリックのときは終了
  break if Miyako::Input.quit_or_escape?
  # 時間が来たら画面内容の更新
  if wait.finish?
    screen, info = draw_liner(screen, info)
    wait.start
  end
  # 画面の描画
  # 画面の消去
  Miyako::Screen.clear
  # 線形配列結果の表示
  screen.render
  # 情報画像の表示
  info.render
  # 画面の更新
  Miyako::Screen.render
end

