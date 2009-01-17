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
    @yuki = Yuki.new
    @yuki.select_textbox(message_box[:box])
    @man = Sprite.new(:file=>"image/start.png", :type=>:ck)
    @man.center.bottom
    @alpha = 0.0
    @wait = WaitCounter.new(0.2)
    @exec = self.method(:view_in)
  end

  def setup
    @yuki.setup
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
        @yuki.start_plot(self.method(:plot))
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
  
  def plot(yuki)
    yuki.text("「レディ〜ス　エ〜ン　ジェントルメ〜ン！」").pause.cr
    yuki.text("「本日も、視聴者参加バラエティー").cr
    yuki.text("　『ルーム３』の時間がは〜じまりま〜した〜！」").pause.clear
    yuki.text("「司会はわたくし、").cr
    yuki.wait 0.3
    yuki.text("　サミュエル・ボチボチデンナーが").cr
    yuki.text("　お送りしま〜す！」").pause.clear
    yuki.text("「本日も、難関を乗り越え、").cr
    yuki.text("　豪華賞品をゲットするだけ！").cr
    yuki.wait 0.5
    yuki.text("　カンタン！」").pause.clear
    yuki.text("「ルールもカンタン！").cr
    yuki.text("　３つの部屋にいる住人からヒントを得て、").pause.cr
    yuki.text("　合言葉を見つけるだけ！").cr
    yuki.wait 0.5
    yuki.text("　ほら、カンタンでしょ？」").pause.clear
    yuki.text("「でも、これらの部屋にいる住人、").cr
    yuki.text("　一筋縄じゃ合い言葉を教えてくれない。").cr
    yuki.wait 0.5
    yuki.text("　いろいろ話して、").cr
    yuki.text("　合い言葉をゲットしてくれ！」").pause.clear
    yuki.text "「さぁ、最初の挑戦者だ。"
    yuki.wait 0.5
    yuki.text "お名前は？"
    yuki.wait 1.5
    yuki.cr
    yuki.text "　・・・おおー、元気いいねー！"
    yuki.wait 0.5
    yuki.cr
    yuki.text "　じゃあ、どっから来たの？"
    yuki.wait 1.0
    yuki.cr
    yuki.text("　・・・オーケイ、よくできました！」").pause.clear
    yuki.text "「じゃ、ルールは分かるよね？"
    yuki.wait 0.5
    yuki.cr
    yuki.text "　・・・よし」"
    yuki.pause.clear
    yuki.text "「ドキドキするねぇ、"
    yuki.wait 0.5
    yuki.cr
    yuki.text "　ワクワクするねぇ"
    yuki.pause.cr
    yuki.text "　それじゃ、元気よく、"
    yuki.cr
    yuki.text "　目の前のドアから入ってみよう。」"
    yuki.pause.clear
    yuki.text "「よーい、"
    yuki.wait 0.5
    yuki.text "スタート！」"
    yuki.pause.clear
    return MainScene
  end

  def render
    Bitmap.dec_alpha!(@man, Screen, @alpha)
    message_box.render if @exec == self.method(:exec_yuki)
  end
end
