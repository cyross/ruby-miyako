# -*- encoding: utf-8 -*-
#街を表すイベントクラス
class EventTown
  include MapEvent

  attr_reader :margin
  
  def init(map, x, y)
    # イベント用チップを取得
    @spr = Sprite.new({:filename => "map2.png", :type => :color_key})
    @spr.ox = @spr.oy = @spr.ow = @spr.oh = 32
    @spr.move_to(x, y)
    @coll = Collision.new([0, 0, @spr.ow, @spr.oh], [@spr.x, @spr.y])
    @margin = Size.new(0, 0)
    @parts = CommonParts.instance
    @yuki = Yuki.new
    @yuki.select_textbox(@parts.box[:box])
  end
  
  # キャラとイベントが重なり合っているかの判別
  def met?(param = nil)
    return @coll.collision?(param[:collision])
  end

  # イベントの開始
  def start(param = nil)
    @yuki.start_plot(plot)
  end

  def executing?
    @yuki.executing?
  end

  # イベントの実行
  def plot
    yuki_plot do
      text "　ここが"
      color([255,200,200]){"グリージアの街"}
      text "か・・・。"
      cr
      text "　まぁ、入るつもりは無いが。"
      pause
      clear
    end
  end
  
  def move(dx, dy)
    @spr.move(-dx, -dy)
  end
  
  def move_to(x, y)
    @spr.move_to(x, y)
  end
  
  def update(map_obj, events, params)
    if @yuki.executing?
      @yuki.update
      @parts.box.update_animation
    end
  end

  def render
    @spr.move(-@margin.w, -@margin.h)
    @spr.render
    @spr.move(@margin.w, @margin.h)
  end

  def render_box
    @parts.box.render if @yuki.executing?
  end
end
