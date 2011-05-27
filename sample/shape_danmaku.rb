# encoding: utf-8
# 弾幕サンプル
# 2011.05.28 Cyross Makoto

require 'miyako'

include Miyako

class Shot
  DoublePiR = 2.0*Math::PI

  def initialize(n)
    @number = n # とりあえず入れている
    @alive = true # 生死判定フラグ
    @sprite = Shape.box(:size=>[16,16],:color=>[rand(255),rand(255),rand(255)],:fill=>true)
    @sprite.show
    @algorithm = Fiber.new{|n|
      cnt = 0
      deg = 0.0
      amt = 15.0
      x, y = pos
      rx = rand(n)*16
      ry = rand(n)*16
      dice = 1000 # 1000分の１の確率で死亡
      while(@alive) do
        rad = DoublePiR*deg/360.0
        Fiber.yield [x+(rx*Math.sin(rad)).to_i,y+(ry*Math.cos(rad)).to_i] # 位置を決定→反映のためにFiber離脱
        deg = (deg + amt) % 360.0
        cnt += 1
        if cnt == 1000 # 1000回カウントしたら初期位置を更新
          x, y = pos
          cnt = 0
        end
        @alive = false if rand(dice) == 0 # 生死判定
      end
      @sprite.hide # 弾を隠す
      Fiber.yield [0,0] # 表示しないので、値は適当
    }
  end
  
  def alive?
    @alive
  end
  
  def update
  	return unless @alive
    @sprite.move_to!(*@algorithm.resume)
  end
  
  def render
    @sprite.render
  end
  
  def pos
    [rand(Screen.w-@sprite.w), rand(Screen.h-@sprite.h)]
  end
  
  private :pos
end

arr = Array.new(1000){|n| Shot.new(n) }

Miyako.main_loop do
  break if Input.quit_or_escape?
  arr.each{|shot|
    shot.update
    shot.render
  }
end
