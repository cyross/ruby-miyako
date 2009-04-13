# -*- encoding: utf-8 -*-
#オアシスを表すイベントクラス
class EventOasis
  include MapEvent

  attr_reader :margin
  
  def init(map, x, y)
    # イベント用チップを取得
    @spr = Sprite.new({:filename => "map2.png", :type => :color_key})
    @spr.oy = @spr.ow = @spr.oh = 32
    @spr.move_to(x, y)
    @coll = Collision.new([0, 0, @spr.ow, @spr.oh])
    @pos  = Point.new(x, y)
    @margin = Size.new(0, 0)
    @parts = CommonParts.instance
    @yuki = Yuki.new
    @yuki.select_textbox(@parts.box[:box])
  end
  
  # キャラの立ち位置とイベントの位置が重なり合っているかの判別
  def met?(param = nil)
    return @coll.collision?(@pos, param[:collision], param[:pos])
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
      text "　ここは"
      color(:cyan){"オアシス"}
      text "のようだ。\n　しかし、普通は砂漠にあるはずなのに・・・。"
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

  # イベントキャラクタの描画
  def render
    @spr.move(-@margin.w, -@margin.h)
    @spr.render
    @spr.move(@margin.w, @margin.h)
  end

  #(Yuki起動時)メッセージボックスの表示
  def render_box
    @parts.box.render if @yuki.executing?
  end
end
