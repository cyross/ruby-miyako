# -*- encoding: utf-8 -*-
# エンディング定義
class Ending
  include Story::Scene
  include MainComponent
  
  def init
    @yuki = Yuki.new
    @yuki.select_textbox(message_box[:box])
    @bg = Sprite.new(:file => "image/congratulation_bg.png", :type => :as)
    @bg.oh = @bg.h / 2
    @anim = SpriteAnimation.new(:sprite=>@bg, :wait=>0.5)
    @cong_text = Sprite.new(:file=>"image/congra.png", :type => :ck)
    @cong_text.centering
    @visible_cong_text = false
    @cong_man = Sprite.new(:file=>"image/congratulation.png", :type => :ck)
    @cong_man.center.bottom
    @visible_cong_man = false
    @timer = WaitCounter.new(3)
    @staff_roll = [Shape.text(:font=>message_box[:box].font, :align=>:center){
                     text "シナリオ・グラフィック・"
                     cr
                     text "スクリプティング・その他雑用"
                     cr.cr
                     text "サイロス　誠"
                   },
                   Shape.text(:font=>message_box[:box].font){ text "Powerd By Miyako 2.0" }
                  ]
    @staff_roll.each{|st|
      st.snap(message_box)
      st.centering
    }
    @index = -1

    @end_roll = Shape.text(:font=>message_box[:box].font){ text "Ｔ　Ｈ　Ｅ　　Ｅ　Ｎ　Ｄ" }
    @end_roll.snap(message_box)
    @end_roll.centering
    @yuki.regist_parts(:end_roll, @end_roll)
    
    @exec = self.method(:view_in1)
  end

  def setup
    @yuki.setup
    @anim.start
    @timer.start
  end

  def update
    return nil if Input.quit_or_escape?
    @anim.update_animation
    return @exec.call
  end
  
  def render
    @anim.render
    @cong_text.render
    @cong_man.render if @visible_cong_man
    if @exec == self.method(:plot_executing)
      @yuki.render
      message_box.render
      @staff_roll[@index].render if @index >= 0
    end
  end
  
  def view_in1
    if @timer.finish?
      @visible_cong_man = true
      @timer.start
      @exec = self.method(:view_in2)
    end
    return @now
  end

  def view_in2
    if @timer.finish?
      @exec = self.method(:plot_executing)
      @yuki.start_plot(@yuki.to_plot(self, :plot))
    end
    return @now
  end

  def plot_executing
    message_box.update_animation
    command_box.update_animation
    @yuki.update
    r = @yuki.executing? ? @now : @yuki.result
    if @yuki.is_scenario?(r)
      @yuki.exec_plot(r)
      r = @now
    end
    return r
  end
  
  def plot(yuki)
    yuki.text "「コ〜ン　"
    yuki.wait 0.3
    yuki.text "グラッチュ　"
    yuki.wait 0.3
    yuki.text "レ〜ショ〜ン♪」"
    yuki.pause.cr
    yuki.text "「いやぁ、"
    yuki.wait 0.2
    yuki.text "見事難関をクリアしたとはオドロキだ！"
    yuki.pause.cr
    yuki.text "　君には全くもって、感服だ！」"
    yuki.pause.clear
    yuki.text "「勿論、クリアしたんだから"
    yuki.wait 0.5
    yuki.cr
    yuki.text "　商品をプレゼントしなくちゃね！」"
    yuki.pause.clear
    text_wait "「まずは", "・", "・", "・"
    yuki.text "「青いはいからうどん」１年分！"
    yuki.wait 0.5
    yuki.cr
    text_wait "　次に", "・", "・", "・"
    yuki.text "いつも真っ赤「炎天下ツアー」！"
    yuki.wait 0.5
    yuki.cr
    text_wait "　最後に", "・", "・", "・"
    yuki.text "「緑のバルーン」提供の沖縄旅行！"
    yuki.wait 0.5
    yuki.cr
    yuki.text "　現地集合現地解散！"
    yuki.wait 0.5
    yuki.cr
    yuki.text "　さ、遠慮せずにうけとってくれ！」"
    yuki.pause.clear
    yuki.text "「今日は見事クリアされたけど、"
    yuki.cr
    yuki.text "　次回はもっと"
    yuki.color(:red){ "ヒィヒィ"}
    yuki.text "言わせる"
    yuki.cr
    yuki.text "　仕掛けを用意するから覚悟しとけよ〜！」"
    yuki.pause.clear
    yuki.text "「次回の挑戦者はキミだ！"
    yuki.wait 0.5
    yuki.cr
    yuki.text "　じゃ、また来週！　"
    yuki.wait 0.5
    yuki.text "バイバ〜イ！」"
    yuki.pause.clear
    staff_roll
    yuki.show :end_roll
    yuki.pause.clear
    yuki.hide :end_roll
    return nil
  end
  
  def text_wait(*txt)
    txt.each{|t|
      @yuki.text t
      @yuki.wait 0.3
    }
  end
  
  def staff_roll
    @staff_roll.length.times{|idx|
      @index = idx
      @yuki.wait 2.0
    }
    @index = -1
  end

  def final
    @anim.stop
  end

  def dispose
    @cong_man.dispose
    @cong_text.dispose
    @anim.dispose
  end
end
