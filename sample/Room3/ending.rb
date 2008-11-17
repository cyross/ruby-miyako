# エンディング定義
class Ending
  include Story::Scene
  include Yuki
  include MainComponent
  
  def init
    init_yuki(message_box, command_box, :box)
    @bg = Sprite.new(:file => "image/congratulation_bg.png", :type => :as)
    @bg.oh = @bg.h / 2
    @anim = SpriteAnimation.new(:sprite=>@bg, :wait=>0.5)
    @anim.dp = 0
    @cong_text = Sprite.new(:file=>"image/congra.png", :type => :ck)
    @cong_text.dp = 700
    @cong_text.centering
    @cong_man = Sprite.new(:file=>"image/congratulation.png", :type => :ck)
    @cong_man.dp = 800
    @cong_man.center.bottom
    @timer = WaitCounter.new(3)
    @staff_roll = [Shape.text(:font=>message_box[:box].font, :align=>:center){
                     text "シナリオ・グラフィック・"
                     cr
                     text "スクリプティング・その他雑用"
                     cr.cr
                     text "サイロス　誠"
                   },
                   Shape.text(:font=>message_box[:box].font){ text "Powerd By Miyako 1.5" }                   
                  ]
    @staff_roll.each{|st|
      st.dp = 3000 # 最前面に
      st.snap(message_box)
      st.centering
    }
    @end_roll = Shape.text(:font=>message_box[:box].font){ text "Ｔ　Ｈ　Ｅ　　Ｅ　Ｎ　Ｄ" }
    @end_roll.snap(message_box)
    @end_roll.centering
    @end_roll.dp = 3000 # 最前面に
  end

  def setup
    setup_yuki
    @anim.start.show
    @cong_text.show
    @timer.start
  end

  def view_in
    if @timer.finish? && @cong_man.visible == false
      @cong_man.show
      @timer.start
    end
    return @timer.waiting?
  end

  def plot
    text "「コ〜ン　"
    wait 0.3
    text "グラッチュ　"
    wait 0.3
    text "レ〜ショ〜ン♪」"
    pause.cr
    text "「いやぁ、"
    wait 0.2
    text "見事難関をクリアしたとはオドロキだ！"
    pause.cr
    text "　君には全くもって、感服だ！」"
    pause.clear
    text "「勿論、クリアしたんだから"
    wait 0.5
    cr
    text "　商品をプレゼントしなくちゃね！」"
    pause.clear
    text_wait "「まずは", "・", "・", "・"
    text "「青いはいからうどん」１年分！"
    wait 0.5
    cr
    text_wait "　次に", "・", "・", "・"
    text "いつも真っ赤「炎天下ツアー」！"
    wait 0.5
    cr
    text_wait "　最後に", "・", "・", "・"
    text "「緑のバルーン」提供の沖縄旅行！"
    wait 0.5
    cr
    text "　現地集合現地解散！"
    wait 0.5
    cr
    text "　さ、遠慮せずにうけとってくれ！」"
    pause.clear
    text "「今日は見事クリアされたけど、"
    cr
    text "　次回はもっと"
    color(:red){ "ヒィヒィ"}
    text "言わせる"
    cr
    text "　仕掛けを用意するから覚悟しとけよ〜！」"
    pause.clear
    text "「次回の挑戦者はキミだ！"
    wait 0.5
    cr
    text "　じゃ、また来週！　"
    wait 0.5
    text "バイバ〜イ！」"
    pause.clear
    @staff_roll.each{|st|
      st.show
      wait 2.0
      st.hide
    }
    @end_roll.show
    pause.clear
    @end_roll.hide
  end
  
  def text_wait(*txt)
    txt.each{|t|
      text t
      wait 0.3
    }
  end

  def final
    @cong_man.hide
    @cong_text.hide
    @anim.stop.hide
  end
end
