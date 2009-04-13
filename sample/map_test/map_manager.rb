# -*- encoding: utf-8 -*-
#マップ管理クラス
class MapManager
  extend Forwardable

  attr_reader :mapchip
  
  def initialize
    @moving = false

    #マップチップインスタンスの作成
    @mapchip = MapChipFactory.load("./mapchip.csv")

    #イベントを登録
    em = MapEventManager.new
    em.add(3, EventRouteMarker).
       add(7, EventRouteMarker2).
       add(8, EventTown).
       add(16, EventOasis)

    #マップの作成
    @map = Map.new(@mapchip, "./map_layer.csv", em)

    #海のマップチップを波がアニメーションする画像に置き換え
    @sp = Sprite.new(:file=>"sea.png", :type=>:as)
    @sp.oh = @sp.w
    @ar = SpriteAnimation.new(:sprite=>@sp, :wait=>0.4)
    @map.set_mapchip_base(0, 3, @ar)
  end

  def move(dx, dy)
    @map.move(dx, dy)
    @map.events[0].each{|e| e.move(dx, dy) }
  end
  
  def move_to(x, y)
    @map.events[0].each{|e| e.move(x-@map.pos.x, y-@map.pos.y) }
    @map.move_to(x, y)
  end
  
  def start
    @ar.start
  end
  
  def update
    @ar.update_animation
    @map.events[0].each{|e| e.update(@map, @map.events, nil) }
  end
  
  def render
    @map.render
  end

  def render_event
    @map.events[0].each{|e| e.render }
  end

  def render_event_box
    @map.events[0].each{|e| e.render_box }
  end

  def stop
    @ar.stop
  end
  
  def dispose
    @map.dispose
    @ar.dispose
    @sp.dispose
  end
    
  def_delegators(:@map, :w, :h, :get_code, :get_code_real, :margin, :mapchips, :[])
  def_delegators(:@map, :collision?, :meet?, :cover?, :events)
  def_delegators(:@mapchip, :collision_table, :access_table)
end
