# -*- encoding: utf-8 -*-
#�}�b�v�Ǘ��N���X
class MapManager
  extend Forwardable

  attr_reader :collision
  
  def initialize
    @moving = false

    #�}�b�v�`�b�v�C���X�^���X�̍쐬
    @mp = MapChipFactory.load("./mapchip.csv")

    #�C�x���g��o�^
    em = MapEventManager.new
    em.add(3, EventRouteMarker).
       add(7, EventRouteMarker2).
       add(8, EventTown).
       add(16, EventOasis)

    #�}�b�v�̍쐬
    @map = Map.new(@mp, "./map_layer.csv", em)

    #�����W���R���W�����ݒ�
    @collision = Collision.new(Rect.new(0, 0, @mp.chip_size[0], @mp.chip_size[1]),
                               Point.new(0, 0))

    #�C�̃}�b�v�`�b�v��g���A�j���[�V��������摜�ɒu������
    @sp = Sprite.new(:file=>"sea.png", :type=>:as)
    @sp.oh = @sp.w
    @ar = SpriteAnimation.new(:sprite=>@sp, :wait=>0.4)
    @map.set_mapchip_base(0, 3, @ar)
  end

  def margin
    return @map.margin
  end
  
  def size
    return @mp.chip_size
  end

  def move(dx, dy)
    @map.move(dx, dy)
    @map.events.each{|e| e.move(dx, dy) }
    @collision.move(dx, dy)
  end
  
  def move_to(x, y)
    @map.events.each{|e| e.move(x-@map.pos.x, y-@map.pos.y) }
    @collision.move_to(x, y)
    @map.move_to(x, y)
  end

  def sync_margin
    @map.sync_margin
    @map.events.each{|e| e.margin.resize(*@map.margin) }
  end
  
  def start
    @ar.start
  end
  
  def update
    @ar.update_animation
    @map.events.each{|e| e.update(@map, @map.events, nil) }
  end
  
  def render
    @map.render
  end

  def render_event
    @map.events.each{|e| e.render }
  end

  def render_event_box
    @map.events.each{|e| e.render_box }
  end

  def stop
    @ar.stop
  end
  
  def dispose
    @map.dispose
    @ar.dispose
    @sp.dispose
  end
    
  def_delegators(:@map, :w, :h, :get_code, :get_code_real)
  def_delegators(:@map, :get_amount, :events)
end
