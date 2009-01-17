# -*- encoding: utf-8 -*-
# 道しるべ（１）を表すイベントクラス
class EventRouteMarker
  include MapEvent

  attr_reader :margin, :collision
  
  def init(map, x, y)
    # イベント用チップを取得
    @spr = Sprite.new({:filename => "map2.png", :type => :color_key})
    @spr.ow = @spr.oh = 32
    @spr.ox = 96
    @spr.move_to(x, y)
    @coll = Collision.new([0, 0, @spr.ow, @spr.oh], [@spr.x, @spr.y])
    @margin = Size.new(0, 0)
    @parts = CommonParts.instance
    @yuki = Yuki.new
    @yuki.select_textbox(@parts.box[:box])
    @yuki.select_commandbox(@parts.cbox[:box])
  end

  # キャラとイベントが重なり合っているかの判別
  def met?(param = nil)
    return @coll.collision?(param[:collision])
  end

  # イベントの実行
  def start(param = nil)
    @yuki.start_plot(self.method(:plot))
  end

  def executing?
    @yuki.executing?
  end

  def plot(yuki)
    yuki.text "　ここに立て札がある。"
    yuki.pause
    yuki.clear
    yuki.text "　しかし、そこには何も書かれていない。"
    yuki.pause
    yuki.clear
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

# 道しるべ（２）を表すイベントクラス
class EventRouteMarker2
  include MapEvent

  attr_reader :margin
  
  def init(map, x, y)
    # イベント用チップを取得
    @spr = Sprite.new({:filename => "map2.png", :type => :color_key})
    @spr.ow = @spr.oh = 32
    @spr.ox = 96
    @spr.move(x, y)
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
    @yuki.start_plot(self.method(:plot))
  end

  def executing?
    @yuki.executing?
  end
  
  def plot(yuki)
    yuki.text "　ここに立て札がある。"
    yuki.pause
    yuki.cr
    yuki.text "　読んでみよう。"
    yuki.pause
    yuki.clear
    yuki.color(:blue){"東"}.text("・・・果て野")
    yuki.cr
    yuki.color(:blue){"西"}.text("・・・荒れ海")
    yuki.cr
    yuki.color(:blue){"南"}.text("・・・グリージアの街")
    yuki.pause
    yuki.clear
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
