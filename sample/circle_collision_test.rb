# encoding: utf-8
# 円コリジョン(CircleCollision)サンプル
# 2009.4.12 Cyross Makoto

require 'Miyako/miyako'

include Miyako

radius = 16
size = [32, 32]
pos = [16, 16]
sprite1 = Sprite.new({:size=>size, :type=>:as})
#Drawing.fill(sprite1, [255,0,0])
Drawing.circle(sprite1, pos, radius, [255,0,0], true)
collision1 = CircleCollision.new(pos, radius)
sprite2 = Sprite.new({:size=>size, :type=>:as})
#Drawing.fill(sprite2, [0,255,0])
Drawing.circle(sprite2, pos, radius, [0,255,0], true)
collision2 = CircleCollision.new(pos, radius)
caution = Shape.text({:font => Font.serif }){ text "collision!" }

sprite1.center.move(0, 128)
sprite2.move_to(176, 0)

amount = 8

Miyako.main_loop do
  break if Input.quit_or_escape?
  if collision1.collision?(sprite1.pos, collision2, sprite2.pos)
    caution.render
  else
    sprite2.move(amount, amount)
  end
  sprite1.render
  sprite2.render
end
