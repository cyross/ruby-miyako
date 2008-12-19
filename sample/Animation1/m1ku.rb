#! /usr/bin/ruby
# M1ku sample for Miyako v2.0
# 2008.11.30 Cyross Makoto

require 'Miyako/miyako'
include Miyako

#Screen.fps_view = true

def create_arm(num)
  spr = Sprite.new(:file=>sprintf("m1ku_arm_#{num}.png"), :type=>:ck)
  spr.move_to(30, 70)
  return spr
end

def create_eye(num)
  spr = Sprite.new(:file=>sprintf("m1ku_eye_#{num}.png"), :type=>:ck)
  spr.move_to(356, 114)
  return spr
end

back = Sprite.new(:file=>"m1ku_back.jpg", :type=>:as)
backs = SpriteAnimation.new(:sprite=>Array.new(12){|n| back.to_sprite{|sprite| Bitmap.hue!(sprite, sprite, 30 * n) }}, :wait => 0.1).start

body = Sprite.new(:file=>"m1ku_body.png", :type=>:ck)
body.move_to(200, 64)

hair_f = Sprite.new(:file=>"m1ku_hair_front.png", :type=>:ck)
hair_f.move_to(200, 24)

hair_r = Sprite.new(:file=>"m1ku_hair_rear.png", :type=>:ck)
hair_r.move_to(200, 24)

arms = Array.new
(0..3).each{|n| arms.push(create_arm(n)) }
arm_anim_param = { 
  :sprite=> arms,
  :wait => 0.1,
  :pattern_list => [0, 1, 2, 3, 2, 1]
}
arm_anim = SpriteAnimation.new(arm_anim_param)
arm_anim.start

eyes = Array.new
(0..3).each{|n| eyes.push(create_eye(n)) }
eye_anim_param = { 
  :sprite => eyes,
  :wait => [4.5, 0.1, 0.1, 0.1, 0.1, 0.1],
  :pattern_list => [0, 1, 2, 3, 2, 1]
}
eye_anim = SpriteAnimation.new(eye_anim_param)
eye_anim.start

damt = 30

# Main Routine
Miyako.main_loop do
  break if Input.quit_or_escape?
  backs.render
  backs.update_animation
  hair_r.render
  arm_anim.update_animation
  arm_anim.render
  body.render
  eye_anim.update_animation
  eye_anim.render
  hair_f.render
end
