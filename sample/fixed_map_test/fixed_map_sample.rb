#encoding: UTF-8
# FixedMap Sample
# 2009.4.12 Cyross Makoto

require 'Miyako/miyako'

include Miyako

Screen::fps_view = true

# Monster Class
class Monster
  extend Forwardable

  def initialize(map, name, size, wait, pattern, x, y)
    @spr = Sprite.new({:filename => name, :type => :color_key})
    @spr.ow = size
    @spr.oh = size
    @coll = Collision.new(Rect.new(0, 0, @spr.ow, @spr.oh))
    @cpos = Point.new(x, y)
    ap = { }
    ap[:sprite] = @spr
    ap[:wait] = wait
    ap[:pattern_list] = pattern
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
    @interval = 2
    @interval_x = 0
    @interval_y = 0
    @cnt = 0
    @wait0 = WaitCounter.new(0.1)
    @wait = WaitCounter.new(0.4)
    @types = 5
    # 方向による移動量リスト
    @ary = [[       0, @spr.oh,          0, @interval, @spr.oh],
            [ @spr.ow,       0,  @interval,         0, @spr.ow],
            [-@spr.ow,       0, -@interval,         0, @spr.ow],
            [       0,-@spr.oh,          0,-@interval, @spr.oh]]
  end

  def update(map, events, param)
    super
    return if @wait.waiting? || @wait0.waiting?
    if @cnt > 0
      @anim.move(@interval_x, @interval_y)
      @cpos.move(@interval_x, @interval_y)
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
      # スライムが当たっているマップ位置リストを取得
      colls = Utility.product_position(
                @cpos.dup.move(data[0], data[1]), @coll.rect, map.mapchips[0].chip_size.to_a
              )
      # 障害物に当たってない？
      if colls.inject(true){|r, pos| r &= map[0].can_access?(0, :in, @cpos, data[0], data[1]) }
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
mp = MapChipFactory.load("./mapchip.csv")
@fmap = FixedMap.new(mp, "./map.csv", em)

Miyako.main_loop do
  break if Input.quit_or_escape?
  dx, dy = Input.trigger_amount.map{|v| v * 4 }
  dx = 0 unless Utility.in_bounds?([@fmap.rect.x,@fmap.rect.x+@fmap.rect.w-1], [0,Screen.w-1], dx)
  dy = 0 unless Utility.in_bounds?([@fmap.rect.y,@fmap.rect.y+@fmap.rect.h-1], [0,Screen.h-1], dy)
  @fmap.move(dx, dy)
  @fmap.events.each{|ee| ee.each{|e| e.update(@fmap, @fmap.events, nil)}}
  @fmap.render_to(Screen)
  @fmap.events.each{|ee| ee.each{|e| e.render}}
end
