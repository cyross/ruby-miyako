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
    
    wc = Sprite.new({:file => "wait_cursor.png", :type => :ac})
    wc.oh = wc.w
    
    wc = SpriteAnimation.new({:sprite => wc, :wait => 0.2, :pattern_list => [0, 1, 2, 3, 2, 1]})
    sc = Sprite.new({:file => "cursor.png", :type => :ac})
    sc.oh = sc.w

    sc = SpriteAnimation.new({:sprite => sc, :wait => 0.2, :pattern_list => [0, 1, 2, 3, 2, 1]})
    tb = TextBox.new({:size => [20, 4], :font => font, :wait_cursor => wc, :select_cursor => sc})
    tb.pause_type = :out
    tb.dp = 1000
 
    cb = TextBox.new({:size => [8, 8], :font => cfont, :wait_cursor => wc, :select_cursor => sc})
    cb.dp = 1200

    bg = Sprite.new({:size=>tb.size, :type=>:ac})
    bg.fill([0,0,255,64])
    bg.dp = 990

    cbg = Sprite.new({:size=>cb.size, :type=>:ac})
    cbg.fill([0,255,0,64])
    cbg.dp = 1190

    @box = Parts.new(bg)
    @box[:box] = tb
    @box.center.bottom{|body| wc.oh }

    @cbox = Parts.new(cbg)
    @cbox[:box] = cb
    @cbox.right{|body| 2.percent(body) }.top{|body| 2.percent(body) }

    @executing = false

  end
end
