# -*- encoding: utf-8 -*-
class Title
  include Story::Scene

  def self.scene_type
    return :scene
  end

  def init
    font = Font.sans_serif
    font.size = 24
    font.color = Color[:white]
    @push_key = Shape.text(:text=>"Push Any Key", :font=>font)
    @push_key.center.bottom{|body| (0.1).ratio(body) }

    @copy_right = Shape.text(:text=>"2006-2008 Cyross Makoto", :font=>font)
    @copy_right.center.bottom{|body| (0.05).ratio(body) }

    @visible = false

    @title = Sprite.new(:file=>"image/mittsu_no_oheya.png", :type=>:ck)
    
    @exec = self.method(:view_in)
  end

  def setup
    @title.move_to(Screen.w, 0)
  end

  def view_in
    if @title.x > 0
      @title.move(-8, 0)
      return @now
    end
    @visible = true
    @exec = self.method(:waiting)
    return @now
  end

  def waiting
    if Input.pushed_any? || Input.click?(:left)
      @exec = self.method(:view_out)
      @visible = false
    end
    return @now
  end

  def view_out
    if @title.x > -Screen.w
      @title.move(-8, 0)
      return @now
    end
    return TitleCall
  end
  
  def update
    return nil if (Input.pushed_any?(:esc) || Input.quit?)
    return @exec.call
  end

  def render
    @title.render
    if @visible
      @push_key.render
      @copy_right.render
    end
  end
end

class TitleCall
  include Story::Scene
  include MainComponent

  def init
    @yuki = Yuki.new(message_box[:box]){|box|
      select_textbox(box)
    }
    @man = Sprite.new(:file=>"image/start.png", :type=>:ck)
    @man.center.bottom
    @alpha = 0.0
    @wait = WaitCounter.new(0.2)
    @exec = self.method(:view_in)
  end

  def setup
    @yuki.setup(plot){|plot|
      select_plot(plot)
    }
    @yuki.vars[:next] = MainScene
    @wait.start
  end

  def update
    return nil if (Input.pushed_any?(:esc) || Input.quit?)
    return @exec.call
  end
  
  def final
    message_box.stop
  end
  
  def view_in
    if @wait.finish?
      if @alpha == 1.0
        @yuki.start_plot
        @exec = self.method(:exec_yuki)
        message_box.start
        return @now
      end
      @alpha += 0.15
      @alpha = 1.0 if @alpha >= 1.0
      @wait.start
    end
    return @now
  end

  def exec_yuki
    message_box.update_animation
    @yuki.update
    return @yuki.result ? @yuki.result : @now
  end
  
  def plot
    yuki_plot do
      text("「レディ〜ス　エ〜ン　ジェントルメ〜ン！」").pause.cr
      text("「本日も、視聴者参加バラエティー").cr
      text("　『ルーム３』の時間がは〜じまりま〜した〜！」").pause.clear
      text("「司会はわたくし、").cr
      wait 0.3
      text("　サミュエル・ボチボチデンナーが").cr
      text("　お送りしま〜す！」").pause.clear
      text("「本日も、難関を乗り越え、").cr
      text("　豪華賞品をゲットするだけ！").cr
      wait 0.5
      text("　カンタン！」").pause.clear
      text("「ルールもカンタン！").cr
      text("　３つの部屋にいる住人からヒントを得て、").pause.cr
      text("　合言葉を見つけるだけ！").cr
      wait 0.5
      text("　ほら、カンタンでしょ？」").pause.clear
      text("「でも、これらの部屋にいる住人、").cr
      text("　一筋縄じゃ合い言葉を教えてくれない。").cr
      wait 0.5
      text("　いろいろ話して、").cr
      text("　合い言葉をゲットしてくれ！」").pause.clear
      text "「さぁ、最初の挑戦者だ。"
      wait 0.5
      text "お名前は？"
      wait 1.5
      cr
      text "　・・・おおー、元気いいねー！"
      wait 0.5
      cr
      text "　じゃあ、どっから来たの？"
      wait 1.0
      cr
      text("　・・・オーケイ、よくできました！」").pause.clear
      text "「じゃ、ルールは分かるよね？"
      wait 0.5
      cr
      text "　・・・よし」"
      pause.clear
      text "「ドキドキするねぇ、"
      wait 0.5
      cr
      text "　ワクワクするねぇ"
      pause.cr
      text "　それじゃ、元気よく、"
      cr
      text "　目の前のドアから入ってみよう。」"
      pause.clear
      text "「よーい、"
      wait 0.5
      text "スタート！」"
      pause.clear
      vars[:next]
    end
  end

  def render
    Bitmap.dec_alpha!(@man, Screen, @alpha)
    message_box.render if @exec == self.method(:exec_yuki)
  end
end
