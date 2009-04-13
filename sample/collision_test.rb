# encoding: utf-8
# コリジョン(Collision)サンプル
# 2009.4.12 Cyross Makoto

require 'Miyako/miyako'

include Miyako

size = [32, 32]
rect = [0, 0] + size
sprite1 = Sprite.new({:size=>size, :type=>:as})
sprite1.fill([255,0,0])
collision1 = Collision.new(rect)
sprite2 = Sprite.new({:size=>size, :type=>:as})
sprite2.fill([0,255,0])
collision2 = Collision.new(rect)
caution = Shape.text({:font => Font.serif }){ text "collision!" }

sprite1.center.move(0, 128)
sprite2.center

amount = 8

Miyako.main_loop do
  break if Input.quit_or_escape?
  if Collision.collision?(collision1, sprite1.pos, collision2, sprite2.pos)
    caution.render
  else
    sprite2.move(0, amount)
  end
  sprite1.render
  sprite2.render
end
