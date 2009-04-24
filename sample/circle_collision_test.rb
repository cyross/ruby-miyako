# encoding: utf-8
# 円コリジョン(CircleCollision)サンプル
# 2009.4.25 Cyross Makoto

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

radius = 16
size = [32, 32]
pos = [16, 16]
sprite1 = Sprite.new({:size=>size, :type=>:as})
Drawing.circle(sprite1, pos, radius, [255,0,0], true)
collision1 = CircleCollision.new(pos, radius)
sprite2 = Sprite.new({:size=>size, :type=>:as})
Drawing.circle(sprite2, pos, radius, [0,255,0], true)
collision2 = CircleCollision.new(pos, radius)
caution = Shape.text({:font => Font.serif }){ text "collision!" }

sprite1.center.move(0, 128)
sprite2.move_to(176, 0)

amounts = [8, -8]

amount1 = [amounts.sample, amounts.sample]
amount2 = [amounts.sample, amounts.sample]

Miyako.main_loop do
  break if Input.quit_or_escape?
  if collision1.collision?(sprite1.pos, collision2, sprite2.pos)
    amount1 = [amounts.sample, amounts.sample]
    amount2 = [amounts.sample, amounts.sample]
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
