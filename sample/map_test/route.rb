
# 道しるべ（１）を表すイベントクラス
class EventRouteMarker
  include MapEvent
  include Yuki

  def init
    # イベント用チップを取得
    @spr = Sprite.new({:filename => "map2.png", :type => :color_key})
    @spr.ow = 32
    @spr.oh = 32
    @spr.ox = 96
    @unit = SpriteUnit.new(500, @spr.bitmap, @spr.ox, @spr.oy, @spr.ow, @spr.oh, 0, 0, nil, @spr.viewport)
    @parts = CommonParts.instance
    init_yuki(@parts.box, @parts.cbox, :box)
  end

  def viewport
    return @unit.viewport
  end
  
  def viewport=(vp)
    @unit.viewport = vp
  end

  # キャラとイベントが重なり合っているかの判別
  def met?(param)
    return @spr.collision.collision?(param[:collision])
  end

  # イベントの実行
  def execute(param)
    exec_plot
  end

  def plot
    text "　ここに立て札がある。"
    pause
    clear
    text "　しかし、そこには何も書かれていない。"
    pause
    clear
  end
  
  def update(map_obj, events, params)
    @spr.collision.pos = @event_pos.dup
    @unit.x = @event_pos.x - map_obj.view_pos.x
    @unit.y = @event_pos.y - map_obj.view_pos.y
    Screen.sprite_list.push(@unit)
  end
end

# 道しるべ（２）を表すイベントクラス
class EventRouteMarker2
  include MapEvent
  include Yuki

  def init
    # イベント用チップを取得
    @spr = Sprite.new({:filename => "map2.png", :type => :color_key})
    @spr.ow = 32
    @spr.oh = 32
    @spr.ox = 96
    @unit = SpriteUnit.new(500, @spr.bitmap, @spr.ox, @spr.oy, @spr.ow, @spr.oh, 0, 0, nil, @spr.viewport)
    @parts = CommonParts.instance
    init_yuki(@parts.box, @parts.cbox, :box)
  end

  def viewport
    return @unit.viewport
  end
  
  def viewport=(vp)
    @unit.viewport = vp
  end
  
  # キャラとイベントが重なり合っているかの判別
  def met?(param)
    return @spr.collision.collision?(param[:collision])
  end

  # イベントの実行
  def execute(param)
    exec_plot
  end

  def plot
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
  
  def update(map_obj, events, params)
    @spr.collision.pos = @event_pos.dup
    @unit.x = @event_pos.x - map_obj.view_pos.x
    @unit.y = @event_pos.y - map_obj.view_pos.y
    Screen.sprite_list.push(@unit)
  end
end
