#街を表すイベントクラス
class EventTown
  include MapEvent
  include Yuki

  def init
    # イベント用チップを取得
    @spr = Sprite.new({:filename => "map2.png", :type => :color_key})
    @spr.ow = 32
    @spr.oh = 32
    @spr.ox = 32
    @spr.oy = 32
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

  # イベントの実行
  def plot
    text "　ここが"
    color([255,200,200]){"グリージアの街"}
    text "か・・・。"
    cr
    text "　まぁ、入るつもりは無いが。"
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
