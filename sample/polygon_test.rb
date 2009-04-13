# Drawing.polygonサンプル
# 2009.4.12 Cyross Makoto

require 'Miyako/miyako'

max_vertexes = 32 # 最大頂点数

# 設定配列(Enumerator)
flags = [[true, true],   # 塗りつぶし、アンチエイリアス有り
         [true],         # 塗りつぶし
         [false, true],  # 線描、アンチエイリアス有り
         [false]         # 線描
        ].cycle

# 色配列(Enumerator)
colors = [[0,0,255],    # 青色
          [0,255,0],    # 緑色
          [0,255,255],  # 水色
          [255,0,0],    # 赤色
          [255,0,255],  # 紫色
          [255,255,0],  # 黄色
          [255,255,255] # 白色
         ].cycle

loop do
  Miyako::Input.update
  break if Miyako::Input.quit_or_escape?
  # 3 ～ max_vertexes までのランダム個数の頂点を作成
  pairs = Array.new(rand(max_vertexes - 3) + 3){
            [rand(Miyako::Screen.w), rand(Miyako::Screen.h)]
          }
  # 多角形を描画
  Miyako::Drawing.polygon(Miyako::Screen, pairs, colors.next, *(flags.next))
  Miyako::Screen.render
end
