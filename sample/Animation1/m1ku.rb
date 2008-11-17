#! /usr/bin/ruby
# M1ku sample for Miyako v1.5
# 2008.3.5 Cyross Makoto

require 'Miyako/miyako'
require 'Miyako/idaten_miyako'

include Miyako

def create_arm(num)
  spr = Sprite.new({:file=>sprintf("m1ku_arm_#{num}.png"), :type=>:ck})
  spr.dp = 150
  spr.move_to(30, 70)
  return spr
end

def create_eye(num)
  spr = Sprite.new({:file=>sprintf("m1ku_eye_#{num}.png"), :type=>:ck})
  spr.dp = 250
  spr.move_to(356, 114)
  return spr
end

back = Sprite.new({:file=>"m1ku_back.jpg", :type=>:ac})
back.dp = -100
back.show

body = Sprite.new({:file=>"m1ku_body.png", :type=>:ck})
body.dp = 200
body.move_to(200, 64)
body.show

hair_f = Sprite.new({:file=>"m1ku_hair_front.png", :type=>:ck})
hair_f.move_to(200, 24)
hair_f.dp = 300
hair_f.show

hair_r = Sprite.new({:file=>"m1ku_hair_rear.png", :type=>:ck})
hair_r.move_to(200, 24)
hair_r.dp = 100
hair_r.show

arms = Array.new
(0..3).each{|n| arms.push(create_arm(n)) }
arm_anim_param = { 
  :sprite=> arms,
  :wait => 0.1,
  :pattern_list => [0, 1, 2, 3, 2, 1]
}
arm_anim = SpriteAnimation.new(arm_anim_param)
arm_anim.start
arm_anim.show

eyes = Array.new
(0..3).each{|n| eyes.push(create_eye(n)) }
eye_anim_param = { 
  :sprite => eyes,
  :wait => [4.5, 0.1, 0.1, 0.1, 0.1, 0.1],
  :pattern_list => [0, 1, 2, 3, 2, 1]
}
eye_anim = SpriteAnimation.new(eye_anim_param)
eye_anim.start
eye_anim.show

# Main Routine
Miyako.main_loop do
  break if Input.quit_or_escape?
end
