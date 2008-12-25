#! /usr/bin/ruby
# FixedMap Sample
# 2008.11.29 C.Makoto

require 'Miyako/miyako'
#require 'Miyako/idaten_miyako'

include Miyako

# Monster Class
class Monster
  extend Forwardable

  def initialize(map, name, size, wait, pattern, x, y)
    @spr = Sprite.new({:filename => name, :type => :color_key})
    @spr.ow = size
    @spr.oh = size
    @coll= Collision.new(Rect.new(0, 0, @spr.ow, @spr.oh),
                          Point.new(@spr.x, @spr.y))
    @coll.amount = Size.new(1, 1)
    ap = { }
    ap[:sprite] = @spr
    ap[:wait] = wait
    ap[:pattern_list] = pattern
#    ap[:position_offset] = [0,2,4,6,8,10,12,14]
    @anim = SpriteAnimation.new(ap)
    @anim.snap(map)
    @anim.left.top.move(x, y)
  end

  def start
    @anim.start
  end
  
  def update(map, events, param)
    @anim.update_animation
  end

  def render
    @anim.render
  end

  def finish
  end
  
  def dispose
    @anim.dispose
    @spr.dispose
  end

  def_delegators(:@anim, :start, :stop)
end

class Slime < Monster
  def initialize(map, x, y)
    super(map, "monster.png", 32, 0.5, [0, 1, 2, 3, 2, 1], x, y)
    @pos = Point.new(x, y)
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

  def update(map, events, param)
    super
    return if @wait.waiting? || @wait0.waiting?
    if @cnt > 0
      @anim.move(@interval_x, @interval_y)
      @coll.move(@interval_x, @interval_y)
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
      @coll.direction.move_to(*(data[0..1]))
      
      ret = map.get_amount_by_rect(0, @spr.rect, @coll)
      
      if (ret.amount[0] | ret.amount[1]) != 0
        @interval_x, @interval_y = data[2..3]
        @cnt = data[4]
      end
    end
  end
end

class SlimeEvent
  include MapEvent

  def init(map, x, y)
    @slime = Slime.new(map, x, y)
  end
  
  def update(map, events, param)
    @slime.update(map, events, param)
  end
  
  def final
    @slime.finish
  end

  def dispose
    @slime.dispose
  end
  
  def render
    @slime.render
  end
end

em = MapEventManager.new
em.add(1, SlimeEvent)

# main

#@a = Sprite.new({:file=>"cursor.png", :type=>:ac })
#@a.oh = @a.w
#@a = SpriteAnimation.new({:sprite=>@a, :wait=>0.1, :pattern_list=>[0,1,2,3,2,1] })
#@a.start

mp = MapChipFactory.load("./mapchip.csv")
@fmap = FixedMap.new(mp, "./map.csv", em)
#@fmap.set_mapchip_base(0, 4, @a)
#@fmap.map_layers[0].mapchip_units[4] = @a

Miyako.main_loop do
  break if Input.quit_or_escape?
#  @a.update_animation
  dx, dy = Input.trigger_amount.map{|v| v * 4 }
  dx = 0 unless Screen.viewport.in_bounds_x?(@fmap.rect, dx)
  dy = 0 unless Screen.viewport.in_bounds_y?(@fmap.rect, dy)
  @fmap.move(dx, dy)
  @fmap.events.each{|e| e.update(@fmap, @fmap.events, nil)}
  @fmap.render
  @fmap.events.each{|e| e.render}
end
