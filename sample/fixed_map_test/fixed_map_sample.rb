#! /usr/bin/ruby
# FixedMap Sample
# 2008.3.2 C.Makoto

require 'Miyako/miyako'
require 'Miyako/idaten_miyako'

include Miyako

# Monster Class
class Monster
  extend Forwardable

  def initialize(name, size, wait, pattern, pos)
    @spr = Sprite.new({:filename => name, :type => :color_key})
    @spr.ow = size
    @spr.oh = size
    @spr.move(*(pos.to_a))
    @spr.collision.amount = Size.new(1, 1)
    ap = { }
    ap[:sprite] = @spr
    ap[:wait] = wait
    ap[:pattern_list] = pattern
#    ap[:position_offset] = [0,2,4,6,8,10,12,14]
    @anim = SpriteAnimation.new(ap)
    @anim.start
    @anim.show
  end

  def update(map, events, param)
  end

  def finish
    @spr.dispose
  end

  def_delegators(:@anim, :start, :stop)
end

class Slime < Monster
  def initialize(pos)
    super("monster.png", 32, 0.5, [0, 1, 2, 3, 2, 1], pos)
    @pos = pos.dup
    @interval = 2
    @interval_x = 0
    @interval_y = 0
    @cnt = 0
    @wait0 = WaitCounter.new(0.1)
    @wait = WaitCounter.new(0.4)
    @types = 5
    @ary = [[ 0, 1, 0, @interval, @spr.oh],
            [ 1, 0, @interval, 0, @spr.ow],
            [-1, 0,-@interval, 0, @spr.ow],
            [ 0,-1, 0,-@interval, @spr.oh]]
  end

  def update_pos(delta)
    @spr.move_to(@spr.x+delta.x, @spr.y+delta.y)
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
    val = rand(@types)
    if val == 0
      @interval_x = 0
      @interval_y = 0
      @wait.start
    else
      data = @ary[val-1]
      @spr.collision.direction = data[0..1]
      
      ret = map.get_amount_by_rect(0, @spr.rect, @spr.collision)
      
      if (ret.amount[0] | ret.amount[1]) != 0
        @interval_x, @interval_y = data[2..3]
        @cnt = data[4]
      end
    end
  end
end

class SlimeEvent
  include MapEvent

  def init
    @slime = Slime.new(@event_pos)
  end
  
  def update_pos
    @slime.update_pos(@delta)
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

@a = Sprite.new({:file=>"cursor.png", :type=>:ac })
@a.oh = @a.w
@a = SpriteAnimation.new({:sprite=>@a, :wait=>0.1, :pattern_list=>[0,1,2,3,2,1] })
@a.start

mp = MapChipFactory.load("./mapchip.csv")
@fmap = FixedMap.new(mp, "./map.csv")
#@fmap.set_mapchip_base(0, 4, @a)
#@fmap.map_layers[0].mapchip_units[4] = @a
@fmap.show

Miyako.main_loop do
  break if Input.quit_or_escape?
  dx, dy = Input.trigger_amount
  @fmap.move(dx, dy)
end
