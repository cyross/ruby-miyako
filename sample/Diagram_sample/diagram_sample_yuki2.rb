# -*- encoding: utf-8 -*-
#! /usr/bin/ruby
# Diagram sample for Miyako v2.0
# 2009.1.16 Cyross Makoto

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

  def render
    @spr.render
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

  def render
    @spr.render
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
  
  def initialize(parts, wait)
    @parts = parts
    @pr = {}
    @pr[:fast] = Diagram::Processor.new{|dia|
      dia.add :scroll, MoveFaster.new(@parts[:c1]), WaitTrigger.new(wait)
      dia.add_arrow(:scroll, nil)
    }
    
    @pr[:slow] = Diagram::Processor.new{|dia|
      dia.add :scroll, MoveSlower.new(@parts[:c2]), WaitTrigger.new(wait)
      dia.add_arrow(:scroll, nil)
    }

    @finished = false
  end

  def start
    @pr.keys.each{|k| @pr[k].start }
  end

  def update
    @finished = @pr.keys.inject(true){|r, k|
      @pr[k].update
      r &= @pr[k].finish?
    } # アニメーション処理が終了するまで繰り返し    
  end

  def stop
    @pr.keys.each{|k| @pr[k].stop }
  end
  
  def render
    @parts[:bk].render
    # 通常なら。@pr[:fast].render,@pr[:slow].renderが筋だが、
    # @pr[:fast]が終了すると、renderを呼んでも描画されないため、元の画像を表示する
    @parts[:c1].render
    @parts[:c2].render
  end
  
  def finish?
    return @finished
  end
end

# Yukiプロット開始
class StartPlot
  include Diagram::NodeBase
  
  def initialize(manager, parts, imgs)
    @manager = manager
    @parts = parts
    @imgs = imgs
    @finished = false
  end

  def start
  end

  def update
    @manager.start_plot
    @parts.start
    @finished = true
  end

  def stop
  end
  
  def render
    @imgs[:bk].render
    @imgs[:c1].render
    @imgs[:c2].render
  end
  
  def finish?
    return @finished
  end
end

# Yukiプロット実行
class Plotting
  include Diagram::NodeBase
  
  def initialize(manager, parts, imgs, set_wait)
    @manager = manager
    @parts = parts
    @imgs = imgs
    @set = set_wait
    @finished = false
  end

  def start
  end

  def update
    @manager.update
    @parts.update
    @parts.update_animation
    @finished = !(@manager.executing?)
  end

  def update_input
    @set.call(0.0) if (Input.pushed_any?(:btn1) || Input.click?(:left)) # １ボタンを押すor左クリックしたら、表示途中のメッセージをすべて表示
  end

  def render
    @imgs[:bk].render
    @imgs[:c1].render
    @imgs[:c2].render
    @manager.render
    @parts.render
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
		@ws = ws
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
    
    @imgs = {}
    @imgs[:c1] = Sprite.new(:file=>"chr01.png", :type=>:ac).bottom
    @imgs[:c2] = Sprite.new(:file=>"chr02.png", :type=>:ac).bottom
    @imgs[:bk] = Sprite.new(:file=>"back.png", :type=>:as).centering

    
    @pr = Diagram::Processor.new{|dia|
      dia.add :move,  Moving.new(@imgs, 0.01)
      dia.add :start, StartPlot.new(@yuki, @parts, @imgs)
      dia.add :plot,  Plotting.new(@yuki, @parts, @imgs, lambda{|w| set_wait(w) })
      dia.add_arrow(:move, :start){|from| from.finish? }
      dia.add_arrow(:start, :plot){|from| from.finish? }
      dia.add_arrow(:plot, nil){|from| from.finish? }
    }

    @base_wait = 0.1 # ウェイト基本値
    @wait = @base_wait # ウェイト
    @exed = false
  end

  def setup
    @pr.start
    @yuki.setup(@box, plot){|box, pl|
      select_textbox box
      select_plot pl
      select_first_page nil # nil, :page1, :page2が選択可能
    }
  end
  
  def update
    return nil if Input.quit_or_escape?
    unless @exed
      @exed = true
      return OverScene
    end
    @pr.update_input
    @pr.update
    return nil if @pr.finish?
    return @now
  end
  
  def render
    @pr.render
  end
  
  def plot
    yuki_plot{
      text_method :string do
        page :page1 do
          text "「ねえ、あんたの担当のセリフ、ちゃんと覚えてるわよねぇ？"
          cr
          pause
          text "　まさか、忘れてたなんて言わないわよねぇ？」"
        end
        clear
        page :page2 do
          color :red do
            size 32 do
              size(24){ "「そんなこと" }
              text "ない"
              size(24){ "よぉ～" }
            end
            cr
            pause
            text "　ちゃんと覚えてるよぉ～」"
            cr
          end
        end
      end
    }
  end
  
  def update_text(yuki, ch)
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

class OverScene
  include Story::Scene

  def OverScene.scene_type
    :over_scene
  end
  
  def init
    @spr = Shape.text(:font=>Font.serif){ text "あいうえお" }
    @max_count = 2000
    @count = 0
    @exed = false
  end

  def update
    unless @exed
      @exed = true
      return OverScene2
    end
    return nil if @count == @max_count
    @count = @count.succ
    return @now
  end
  
  def render
    @spr.render
  end
end

class OverScene2
  include Story::Scene

  def OverScene2.scene_type
    :over_scene
  end
  
  def init
    @spr = Shape.text(:font=>Font.serif){ text "かきくけこ" }
    @max_count = 1000
    @count = 0
  end

  def update
    return nil if @count == @max_count
    @count = @count.succ
    return @now
  end
  
  def render
    @spr.render
  end
end

ds = Story.new
ds.run(MainScene)