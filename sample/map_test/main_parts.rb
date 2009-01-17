# -*- encoding: utf-8 -*-
#共通パーツクラス
class CommonParts
  include Singleton

  attr_reader :box, :cbox
  attr_accessor :executing
  
  def initialize
    # create window
    font = Font.sans_serif
    font.size = 24
    
    cfont = Font.sans_serif
    cfont.size = 16
    
    wcs = Sprite.new({:file => "wait_cursor.png", :type => :ac})
    wcs.oh = wcs.w
    scs = Sprite.new({:file => "cursor.png", :type => :ac})
    scs.oh = scs.w

    wc = SpriteAnimation.new({:sprite => wcs, :wait => 0.2, :pattern_list => [0, 1, 2, 3, 2, 1]})
    sc = SpriteAnimation.new({:sprite => scs, :wait => 0.2, :pattern_list => [0, 1, 2, 3, 2, 1]})
    tb = TextBox.new({:size => [20, 4], :font => font, :wait_cursor => wc, :select_cursor => sc})
    tb.set_wait_cursor_position{|wc, tbox| wc.right.bottom }
 
    wc = SpriteAnimation.new({:sprite => wcs, :wait => 0.2, :pattern_list => [0, 1, 2, 3, 2, 1]})
    sc = SpriteAnimation.new({:sprite => scs, :wait => 0.2, :pattern_list => [0, 1, 2, 3, 2, 1]})
    cb = TextBox.new({:size => [8, 8], :font => cfont, :wait_cursor => wc, :select_cursor => sc})

    bg = Sprite.new({:size=>tb.size, :type=>:ac})
    bg.fill([0,0,255,64])

    cbg = Sprite.new({:size=>cb.size, :type=>:ac})
    cbg.fill([0,255,0,64])

    @box = Parts.new(bg.size)
    @box[:bg] = bg
    @box[:box] = tb
    @box.center.bottom{|body| wc.oh }

    @cbox = Parts.new(cbg.size)
    @cbox[:bg] = cbg
    @cbox[:box] = cb
    @cbox.right{|body| 2.percent(body) }.top{|body| 2.percent(body) }

    @executing = false
  end
  
  def start
    @box.start
    @cbox.start
  end
  
  def stop
    @box.stop
    @cbox.stop
  end
  
  def reset
    @box.reset
    @cbox.reset
  end
  
  def update_animation
    @box.update_animation
    @cbox.update_animation
  end
end
