#! /usr/bin/ruby
# FixedMap Sample
# 2007.12.30 C.Makoto

require 'Miyako/miyako'
require 'Miyako/idaten_miyako'

include Miyako
# Monster Class
class Monster
  extend Forwardable

  def initialize(name, size, wait, pattern, x, y)
    @spr = Sprite.new({:filename => name, :type => :color_key})
    @spr.ow = size
    @spr.oh = size
    @spr.move(x, y)
    aparam = Hash.new
    aparam[:sprite] = @spr
    aparam[:wait] = wait
    aparam[:pattern_list] = pattern
    aparam[:position_offset] = [0,2,4,6,8,10,12,14]
    @anim = SpriteAnimation.new(aparam)
    @anim.start
  end

  def update(map, events, param)
  end

  def finish
    @spr.dispose
  end

  def_delegators(:@anim, :start, :stop)
end

class Slime < Monster
  def initialize(x, y)
    super("monster.png", 32, 0.5, [0, 1, 2, 3, 2, 1], x, y)
    @interval = 2
    @interval_x = 0
    @interval_y = 0
    @amount = @spr.oh
    @cnt = 0
    @wait0 = WaitCounter.new(0.1)
    @wait = WaitCounter.new(0.4)
  end

  def update(map, events, param)
    @anim.update_animation
    return if @wait.waiting? || @wait0.waiting?
    if @cnt > 0
      @spr.move(@interval_x, @interval_y)
      @cnt -= @interval
      @wait0.start
      return
    end
    case rand(5)
    when 0
      @interval_x = 0
      @interval_y = 0
      @wait.start
    when 1
      code = map.getCodeReal(0, @spr.x, @spr.y+@spr.oh)
      if code == -1
        @interval_x = 0
        @interval_y = @interval
        @cnt = @amount
      end
    when 2
      code = map.getCodeReal(0, @spr.x+@spr.ow, @spr.y)
      if code == -1
        @interval_x = @interval
        @interval_y = 0
        @cnt = @amount
      end
    when 3
      code = map.getCodeReal(0, @spr.x-@spr.ow, @spr.y)
      if code == -1
        @interval_x = -@interval
        @interval_y = 0
        @cnt = @amount
      end
    when 4
      code = map.getCodeReal(0, @spr.x, @spr.y-@spr.oh)
      if code == -1
        @interval_x = 0
        @interval_y = -@interval
        @cnt = @amount
      end
    end
  end
end

class SlimeEvent
  include MapEvent

  def init
    @slime = Slime.new(@event_pos.x, @event_pos.y)
  end
  
  def update(map, events, param)
    @slime.update(map, events, param)
  end
  
  def final
    @slime.finish
  end
end

MapEvent.add(1, SlimeEvent)

# main

mp = MapChipFactory.load("./mapchip.csv")
@fmap = FixedMap.new(mp, "./map.csv")
@fmap.show

Miyako.main_loop do
  break if Input.quit_or_escape?
end
