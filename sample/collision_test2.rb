# encoding: utf-8
# コリジョン(Collision・CircleCollision混合)サンプル
# 2009.4.24 Cyross Makoto

require 'Miyako/miyako'

include Miyako

Screen.fps = 60

# Utility.in_bounds?引数生成
def segments(sprite, amounts, idx)
  [
   [sprite.pos[idx], sprite.pos[idx] + sprite.size[idx] - 1],
   [0, Screen.size[idx]],
   amounts[idx]
  ]
end

# 矩形衝突判定と円形衝突判定との切り替え
collision_list = [Collision, CircleCollision].cycle

# 同時表示スプライト数
Sprites = 20

# スプライトサイズ
size = [64, 64]
# スプライト矩形(当たり判定生成用)
rect = [0, 0] + size
# 移動量切り替え
amount = [4, -4]

sprites = Array.new(Sprites){|n|
  # スプライトの生成
  sprite = Sprite.new({:size=>size, :type=>:as})
  Drawing.circle(sprite, [size[0]/2, size[1]/2], size[0]/2, [rand(256),rand(256),rand(256)], true)
  sprite.move_to(rand(Screen.w-size[0]), rand(Screen.h-size[1]))

  # コリジョンの生成
  collision = Collision.new(rect)

  # :collisioned => 当たり判定した？
  {
   :sprite => sprite,
   :collision => collision,
   :amount => [amount.sample, amount.sample]
  }
}

# 衝突判定用の組み合わせ行列を作成
matrix = sprites.combination(2)

cautions = {
  Collision => Shape.text({:font => Font.serif }){ text "矩形衝突判定中" },
  CircleCollision => Shape.text({:font => Font.serif }){ text "円形衝突判定中" }
}

# 初期の衝突判定方法を設定
collision_type = collision_list.next

# 一気にレンダリング
Screen.pre_render_array << sprites.map{|m| m[:sprite]}

# 判定を切り替えるタイミングを決めるタイマー
wait = WaitCounter.new(1.0)
wait.start

Miyako.main_loop do
  break if Input.quit_or_escape?
  
  # 一定時間ごとに衝突判定方法を切り替え
  if wait.finish?
    collision_type = collision_list.next
    wait.start
  end

  # 衝突判定
  # 衝突していたら方向を反転
  matrix.each{|pair|
    p0 = pair[0]
    p1 = pair[1]
    if collision_type.collision?(p0[:collision],
                                 p0[:sprite].pos,
                                 p1[:collision],
                                 p1[:sprite].pos)
      p0[:amount][0] = -p0[:amount][0]
      p0[:amount][1] = -p0[:amount][1]
      p1[:amount][0] = -p1[:amount][0]
      p1[:amount][1] = -p1[:amount][1]
    end
  }

  # 移動
  sprites.each{|s|
    # 画面の端に来たら方向転換
    s[:amount][0] = -s[:amount][0] unless Utility.in_bounds?(*segments(s[:sprite], s[:amount], 0))
    s[:amount][1] = -s[:amount][1] unless Utility.in_bounds?(*segments(s[:sprite], s[:amount], 1))
    s[:sprite].move(*s[:amount])
  }

  # 画面への描画
  Screen.pre_render
  cautions[collision_type].render
end
