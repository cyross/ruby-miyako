#encoding: utf-8
#Drawerクラスサンプル
#画面に星を表示させる
#2010.05.03 Cyross Makoto

require 'miyako'
require 'Miyako/EXT/drawer'

include Miyako

RadianBase = 0.4 * Math::PI # inner point (radian of 72deg)
RadianOffset = 0.2 * Math::PI # inner point (radian of 36deg)
W = 7
H = 5
R = 32
TIMES = 16
ROUND_R = 128

def base_line(sprite)
end

def star_points(r, r2=r*0.4, dx=0, dy=0, rad=0.0, scale=1.0)
  (0...5).to_a.inject([]){|ary, n|
    rad1 = RadianBase * n + Math::PI + rad
    rad2 = rad1 + RadianOffset
    ary.push(Point.new(dx+(Math.sin(rad1)*r*scale).to_i,  dy+(Math.cos(rad1)*r*scale).to_i),
             Point.new(dx+(Math.sin(rad2)*r2*scale).to_i, dy+(Math.cos(rad2)*r2*scale).to_i))
    ary
  }
end

def point_to_s(point)
  sprintf("[%4d,%4d]", point[0], point[1])
end

def points_to_s(points)
  points.map{|pt| point_to_s(pt)}.join("")
end

def multi_star_points(num, r, r2=r*0.4, dx=0, dy=0, rad=0.0, scale=1.0)
  num.times.to_a.map{|n| star_points(r, r2, dx, dy, rad + (n.to_f/num.to_f * 2 * Math::PI), scale) }
end

# axis line
axis = [Drawer.new(:method=>:line, :rect=>[320,0,1,480], :color=>:white), # y-axis
        Drawer.new(:method=>:line, :rect=>[0,240,640,1], :color=>:white)] # x-axis

# circle
circle = SpriteAnimation.new(
  :sprites=>[Drawer.new(:method=>:circle, :r=>48, :point=>[0,0], :color=>:red, :fill=>true)],
  :wait=>0.05,
  :move_offset=>TIMES.times.to_a.map{|n|
    radian = 2*n.to_f/TIMES.to_f*Math::PI
    [320+ROUND_R*Math.sin(radian),
     240+ROUND_R*Math.cos(radian)]
  }
)


# stars
stars = H.times.to_a.map{|y|
  W.times.to_a.map{|x|
    tmp = multi_star_points(8, R, R*0.4, x*R*3+R, y*R*3+R+16).map{|points|
      Drawer.new(:method=>:polygon,
                 :points=>points,
                 :color=>[255,255,255,128],
                 :fill=>true)
    }
    SpriteAnimation.new(:sprites=>tmp, :wait=>0.1)
  }
}

Sprite[:axis] = axis
Sprite[:circle] = circle
Sprite[:stars] = stars

Animation[:circle] = circle
Animation[:stars] = stars

circle.start
stars.start

Miyako.main_loop do
  break if Input.quit_or_escape?
end
