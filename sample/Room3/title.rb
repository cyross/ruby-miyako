class Title
  include Story::Scene
  include MainComponent

  def self.scene_type
    return :scene
  end

  def init
    font = Font.sans_serif
    font.size = 24
    font.color = Color[:white]
    @push_key = Shape.text(:text=>"Push Any Key", :font=>font)
    @push_key.center.bottom{|body| (0.1).ratio(body) }
    @push_key.dp = 300

    @copy_right = Shape.text(:text=>"2006 Cyross Makoto", :font=>font)
    @copy_right.center.bottom{|body| (0.05).ratio(body) }
    @copy_right.dp = 300

    @title = Sprite.new(:file=>"image/mittsu_no_oheya.png", :type=>:ck)
    @title.dp = 200
  end

  def setup
    @title.show
    @title.move_to(Screen.w, 0)
  end

  def view_in
    if @title.x > 0
      @title.move(-8, 0)
      return true
    end
    @push_key.show
    @copy_right.show
    return false
  end

  def update
    return nil if (Input.pushed_any?(:esc) || Input.quit?)
    return Input.pushed_any? ? TitleCall : @now
  end

  def view_out
    if @title.x == 0
      @push_key.hide
      @copy_right.hide
    end
    if @title.x > -Screen.w
      @title.move(-8, 0)
      return true
    end
    return false
  end
end

class TitleCall
  include Story::Scene
  include Yuki
  include MainComponent

  def init
    init_yuki(message_box, command_box, :box)
    @man = Sprite.new(:file=>"image/start.png", :type=>:ck)
    @man.center.bottom
    @man.dp = 10
    @wait = WaitCounter.new(0.2)
  end

  def setup
    @man.alpha = 0
    @man.show
    @wait.start
  end

  def view_in
    if @wait.finish?
      if @man.alpha == 255
        return false
      end
      @man.alpha += 15
      @wait.start
    end
    return true
  end

  def plot
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
    return MainScene
  end
  
  def final
    @man.hide
  end
end
