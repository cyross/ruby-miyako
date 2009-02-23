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
    @yuki.setup(@parts.box[:box]){|box|
      select_textbox(box)
    }
  end

  # キャラとイベントが重なり合っているかの判別
  def met?(param = nil)
    return @coll.collision?(param[:collision])
  end

  # イベントの実行
  def start(param = nil)
    @yuki.start_plot(plot)
  end

  def executing?
    @yuki.executing?
  end

  def plot
    yuki_plot do
      text "　ここに立て札がある。"
      pause
      clear
      text "　しかし、そこには何も書かれていない。"
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
    @yuki.setup(@parts.box[:box]){|box|
      select_textbox(box)
    }
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
  
  def plot
    yuki_plot do
      text "　ここに立て札がある。"
      pause
      cr
      text "　読んでみよう。"
      pause
      clear
      color(:blue){"東"}.text("・・・果て野")
      cr
      color(:blue){"西"}.text("・・・荒れ海")
      cr
      color(:blue){"南"}.text("・・・グリージアの街")
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
