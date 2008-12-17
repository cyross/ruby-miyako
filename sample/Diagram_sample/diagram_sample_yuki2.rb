#! /usr/bin/ruby
# Diagram sample for Miyako v2.0
# 2008.11.23 Cyross Makoto

require 'Miyako/miyako'

include Miyako

# 移動が遅いスクロール
class MoveSlower
  include Diagram::NodeBase
  
  def initialize(spr)
    @spr = spr
    @finish = false # 終了フラグ
  end
  
  def start
    @spr.move_to(640, @spr.y) # 画面を出たところまで移動
  end

  def update
    @finish = (@spr.x <= 320) # 所定の位置までスクロールさせたら終了
    return if @finish
    @spr.move(-2,0)
  end

  def finish?
    return @finish
  end
end

# 移動が速いスクロール
class MoveFaster
  include Diagram::NodeBase
  
  def initialize(spr)
    @spr = spr
    @finish = false # 終了フラグ
  end
  
  def start
    @spr.move_to(640, @spr.y) # 画面を出たところまで移動
  end

  def update
    @finish = (@spr.x <= 40) # 所定の位置までスクロールさせたら終了
    return if @finish
    @spr.move(-4,0)
  end

  def finish?
    return @finish
  end
end

class WaitTrigger
  include Diagram::TriggerBase

  def initialize(wait=0.1)
    @timer = WaitCounter.new(wait)
  end
  
  def pre_process
    @timer.start
  end
  
  def update?
    @timer.finish?
  end
  
  def post_update
    @timer.start
  end
  
  def post_process
    @timer.stop
  end
end

# 移動アニメーションノード
class Moving
  include Diagram::NodeBase
  
  def initialize(chr1, chr2, wait)
    @pr = {}
    @pr[:fast] = Diagram::Processor.new{|dia|
      dia.add :scroll, MoveFaster.new(chr1), WaitTrigger.new(wait)
      dia.add_arrow(:scroll, nil)
    }
    
    @pr[:slow] = Diagram::Processor.new{|dia|
      dia.add :scroll, MoveSlower.new(chr2), WaitTrigger.new(wait)
      dia.add_arrow(:scroll, nil)
    }

    @finished = false
  end

  def start
    @pr.keys.each{|k| @pr[k].start }
  end

  def update
    @finished = @pr.keys.inject(true){|r, k| r &= @pr[k].finish? } # アニメーション処理が終了するまで繰り返し    
  end

  def stop
    @pr.keys.each{|k| @pr[k].stop }
  end
  
  def finish?
    return @finished
  end
end

# Yukiプロット実行
class StartPlot
  include Diagram::NodeBase
  
  def initialize(manager)
    @manager = manager
    @finished = false
  end

  def start
  end

  def update
    @manager.start
    @finished = true
  end

  def stop
  end
  
  def finish?
    return @finished
  end
end

# Yukiプロット実行
class Plotting
  include Diagram::NodeBase
  
  def initialize(manager, set_wait)
    @manager = manager
    @set = set_wait
    @finished = false
  end

  def start
  end

  def update
    @finished = !(@manager.executing?)
  end

  def update_input
    @set.call(0.0) if Input.pushed_any?(:btn1) # １ボタンを押したら、表示途中のメッセージをすべて表示
    @manager.update_input
  end
  
  def stop
  end
  
  def finish?
    return @finished
  end
end

class MainScene
  include Story::Scene

  TEXTBOX_MARGIN = 16
  TEXTBOX_BOTTOM = 24
  
  def init
    ws = Sprite.new(:file=>"wait_cursor.png", :type=>:ac)
    ws.oh = ws.ow
    ws = SpriteAnimation.new(:sprite=>ws, :wait=>0.2, :pattern_list=>[0,1,2,3,2,1])
    cs = Sprite.new(:file=>"cursor.png", :type=>:ac)
    cs.oh = cs.ow
    cs = SpriteAnimation.new(:sprite=>cs, :wait=>0.2, :pattern_list=>[0,1,2,3,2,1])
    font = Font.sans_serif
    font.color = Color[:white]
    font.size = 24
    @box = TextBox.new(:size=>[20,5], :wait_cursor => ws, :select_cursor => cs, :font => font)
    @box_bg = Sprite.new(:size => @box.size.to_a.map{|v| v + TEXTBOX_MARGIN}, :type => :ac)
    @box_bg.fill([0,0,255,128])
    @parts = Parts.new(@box.size)
    @parts[:box_bg] = @box_bg
    @parts[:box] = @box
    @parts[:box_bg].centering
    @parts[:box].centering
    @parts.center.bottom{ TEXTBOX_BOTTOM }

    @yuki = Yuki.new
    @yuki.update_text = self.method(:update_text)
    @y_manager = @yuki.manager(@yuki.to_plot(self, :plot), false, true)
    
    @c1 = Sprite.new(:file=>"chr01.png", :type=>:ac).bottom
    @c2 = Sprite.new(:file=>"chr02.png", :type=>:ac).bottom
    @bk = Sprite.new(:file=>"back.png", :type=>:as).centering

    
    @pr = Diagram::Processor.new{|dia|
      dia.add :move,  Moving.new(@c1, @c2, 0.01)
      dia.add :start, StartPlot.new(@y_manager)
      dia.add :plot,  Plotting.new(@y_manager, lambda{|w| set_wait(w) })
      dia.add_arrow(:move, :start){|from| from.finish? }
      dia.add_arrow(:start, :plot){|from| from.finish? }
      dia.add_arrow(:plot, nil){|from| from.finish? }
    }

    @base_wait = 0.1 # ウェイト基本値
    @wait = @base_wait # ウェイト
  end

  def setup
    @pr.start
    @yuki.setup
    @yuki.select_textbox(@box)
  end
  
  def update
    return nil if Input.quit_or_escape?
    @pr.update_input
    @parts.update_animation
    return nil if @pr.finish?
    return @now
  end
  
  def render
    @bk.render
    @c1.render
    @c2.render
    @parts.render if @y_manager.executing?
  end
  
  def plot(yuki)
    yuki.text "「ねえ、あんたの担当のセリフ、ちゃんと覚えてるわよねぇ？"
    yuki.cr
    unless @wait == 0
      yuki.pause
      reset_wait 
    end
    yuki.text "　まさか、忘れてたなんて言わないわよねぇ？」"
    yuki.cr
    yuki.pause
    reset_wait
    yuki.clear
    yuki.color(:red){
      yuki.size(32){
        yuki.size(24){ "「そんなこと" }
        yuki.text "ない"
        yuki.size(24){ "よぉ～" }
      }
      yuki.cr
      yuki.pause
      reset_wait
      yuki.text "　ちゃんと覚えてるよぉ～」"
      yuki.cr
    }
    yuki.pause
    reset_wait
  end
  
  def update_text(yuki)
    yuki.wait @wait # １文字ずつ表示させる
  end

  def set_wait(wait)
    @wait = wait
  end

  def reset_wait
    @wait = @base_wait
  end
  
  def final
    @pr.stop
  end
end

ds = Story.new
ds.run(MainScene)