# encoding: utf-8
# 円コリジョン(CircleCollision)サンプル
# 2009.4.26 Cyross Makoto

require 'Miyako/miyako'

include Miyako

Screen.fps = 60

AMOUNT_MIN = -8
AMOUNT_MAX = 8

# Utility.in_bounds?引数生成
def segments(sprite, amounts, idx)
  [sprite.segment[idx], Screen.segment[idx], amounts[idx]]
end

# 移動量の決定
def get_amount
  range = AMOUNT_MAX - AMOUNT_MIN
  [[rand(range)+AMOUNT_MIN,
    rand(range)+AMOUNT_MIN],
   [rand(range)+AMOUNT_MIN,
    rand(range)+AMOUNT_MIN]]
end

radius = 32
size = [radius*2, radius*2]
pos = [radius, radius]
sprite1 = Sprite.new({:size=>size, :type=>:as})
Drawing.circle(sprite1, pos, radius, [255,0,0], true)
collision1 = CircleCollision.new(pos, radius)
sprite2 = Sprite.new({:size=>size, :type=>:as})
Drawing.circle(sprite2, pos, radius, [0,255,0], true)
collision2 = CircleCollision.new(pos, radius)
caution = Shape.text({:font => Font.serif }){ text "collision!" }

sprite1.move_to(rand(Screen.w-size[0]), rand(Screen.h-size[1]))
sprite2.move_to(rand(Screen.w-size[0]), rand(Screen.h-size[1]))

amount1, amount2 = get_amount

Miyako.main_loop do
  break if Input.quit_or_escape?
  if collision1.collision?(sprite1.pos, collision2, sprite2.pos)
    amount1, amount2 = get_amount
    caution.render
  end
  amount1[0] = -amount1[0] unless Utility.in_bounds?(*segments(sprite1, amount1, 0))
  amount1[1] = -amount1[1] unless Utility.in_bounds?(*segments(sprite1, amount1, 1))
  amount2[0] = -amount2[0] unless Utility.in_bounds?(*segments(sprite2, amount2, 0))
  amount2[1] = -amount2[1] unless Utility.in_bounds?(*segments(sprite2, amount2, 1))

  sprite1.move(*amount1)
  sprite2.move(*amount2)

  sprite1.render
  sprite2.render

  Font.serif.draw_text(Screen,
                       "distance = #{collision1.interval(sprite1.pos, collision2, sprite2.pos)}",
                       0,
                       Screen.h - Font.serif.line_height
                      )
end
