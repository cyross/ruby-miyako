# -*- encoding: utf-8 -*-
#! /usr/bin/ruby
# Lex sample for Miyako v2.0
# 2008.11.24 Cyross Makoto

require 'Miyako/miyako'

include Miyako

def create_wheel(num)
  spr = Sprite.new({:file=>sprintf("lex_wheel_#{num}.png"), :type=>:ck})
  spr.move_to(317, 331)
  return spr
end


back = Plane.new({:file=>sprintf("lex_back.png"), :type=>:as})
back_timer = WaitCounter.new(0.1)

title = Sprite.new({:file=>sprintf("song_title.png"), :type=>:ck})
pos = Screen.h
upper = 24
x = 24
title.move_to(x, pos)
title_timer = WaitCounter.new(2)
interval = 8
mode = 0

len_body = Sprite.new({:file=>sprintf("lex_body.png"), :type=>:ck})
len_body.move_to(425, 219)

len_anim_param = { 
  :sprite => len_body,
  :wait => 0.1,
  :move_offset => [[0,0], [0,-1], [0,0], [0,1]]
}
len_anim = SpriteAnimation.new(len_anim_param)
len_anim.start

road_roller = Sprite.new({:file=>sprintf("lex_roadroller.png"), :type=>:ck})
road_roller.move_to(310, 180)

rr_anim_param = { 
  :sprite => road_roller,
  :wait => 0.1,
  :move_offset => [[0,0], [0,1], [0,0], [0,-1]]
}
rr_anim = SpriteAnimation.new(rr_anim_param)
rr_anim.start

wheels = Array.new
(0..2).each{|n| wheels.push(create_wheel(n)) }
wheel_anim_param = {
  :sprite => wheels,
  :wait => 0.1,
  :pattern_list => [0, 1, 2, 1]
}
wheel_anim = SpriteAnimation.new(wheel_anim_param)
wheel_anim.start

back_timer.start
title_timer.start
Miyako.main_loop do
  break if Input.quit_or_escape?
  len_anim.update_animation
  rr_anim.update_animation
  wheel_anim.update_animation
  if back_timer.finish?
    back.move(-2, 0)
    back_timer.start
  end
  if title_timer.finish?
    case mode
    when 0
      mode = 1
      title_timer = WaitCounter.new(0.1)
      title_timer.start
    when 1
      pos -= interval
      if pos <= upper
        pos = upper
        mode = 2
      else
        title_timer.start
      end
      title.move_to(x, pos)
    when 2
      # no operation
    end
  end
  back.render
  wheel_anim.render
  len_anim.render
  rr_anim.render
  title.render if mode > 0
end
